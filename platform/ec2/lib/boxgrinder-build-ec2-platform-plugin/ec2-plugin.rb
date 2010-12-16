#
# Copyright 2010 Red Hat, Inc.
#
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 3 of
# the License, or (at your option) any later version.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this software; if not, write to the Free
# Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA, or see the FSF site: http://www.fsf.org.

require 'boxgrinder-build/plugins/base-plugin'
require 'boxgrinder-build/helpers/linux-helper'
require 'tempfile'

module BoxGrinder
  class EC2Plugin < BasePlugin
    REGIONS = {'us_east' => 'url'}

    KERNELS = {
        'fedora' => {
            '11' => {
                'i386' => {:rpm => 'http://repo.oddthesis.org/packages/other/kernel-xen-2.6.21.7-2.fc8.i686.rpm'},
                'x86_64' => {:rpm => 'http://repo.oddthesis.org/packages/other/kernel-xen-2.6.21.7-2.fc8.x86_64.rpm'}
            }
        },
        'centos' => {
            '5' => {
                'i386' => {:rpm => 'http://repo.oddthesis.org/packages/other/kernel-xen-2.6.21.7-2.fc8.i686.rpm'},
                'x86_64' => {:rpm => 'http://repo.oddthesis.org/packages/other/kernel-xen-2.6.21.7-2.fc8.x86_64.rpm'}
            }
        },
        'rhel' => {
            '5' => {
                'i386' => {:rpm => 'http://repo.oddthesis.org/packages/other/kernel-xen-2.6.21.7-2.fc8.i686.rpm'},
                'x86_64' => {:rpm => 'http://repo.oddthesis.org/packages/other/kernel-xen-2.6.21.7-2.fc8.x86_64.rpm'}
            }
        }
    }

    def after_init
      register_deliverable(:disk => "#{@appliance_config.name}.ec2")

      register_supported_os('fedora', ['11', '13', '14'])
      register_supported_os('centos', ['5'])
      register_supported_os('rhel', ['5'])
    end

    def execute
      unless is_supported_os?
        @log.error "EC2 delivery plugin supports following operating systems: #{supported_oses}. Your OS is #{@appliance_config.os.name} #{@appliance_config.os.version}."
        return
      end

      @linux_helper = LinuxHelper.new(:log => @log)

      @log.info "Converting #{@appliance_config.name} appliance image to EC2 format..."

      begin
        # TODO using whole 10GB is fine?
        @image_helper.create_disk(@deliverables.disk, 10)
        @image_helper.create_filesystem(@deliverables.disk)
      rescue => e
        @log.error "Error while preparing EC2 disk image. See logs for more info"
        raise e
      end

      ec2_disk_mount_dir = "#{@dir.tmp}/ec2-#{rand(9999999999).to_s.center(10, rand(9).to_s)}"
      raw_disk_mount_dir = "#{@dir.tmp}/raw-#{rand(9999999999).to_s.center(10, rand(9).to_s)}"

      begin
        ec2_mounts = @image_helper.mount_image(@deliverables.disk, ec2_disk_mount_dir)
        raw_mounts = @image_helper.mount_image(@previous_deliverables.disk, raw_disk_mount_dir)
      rescue => e
        @log.debug e
        raise "Error while mounting image. See logs for more info"
      end

      @image_helper.sync_files(raw_disk_mount_dir, ec2_disk_mount_dir)

      @image_helper.umount_image(@previous_deliverables.disk, raw_disk_mount_dir, raw_mounts)
      @image_helper.umount_image(@deliverables.disk, ec2_disk_mount_dir, ec2_mounts)

      @image_helper.customize(@deliverables.disk) do |guestfs, guestfs_helper|
        # TODO is this really needed?
        @log.debug "Uploading '/etc/resolv.conf'..."
        guestfs.upload("/etc/resolv.conf", "/etc/resolv.conf")
        @log.debug "'/etc/resolv.conf' uploaded."

        create_devices(guestfs)
        upload_fstab(guestfs)

        guestfs.mkdir("/data") if @appliance_config.is64bit?

        enable_networking(guestfs)
        upload_rc_local(guestfs)
        enable_nosegneg_flag(guestfs)
        add_ec2_user(guestfs)
        
        # Commented for now because it restarts the system after relabeling is completed wchich may break some
        # startup scripts
        # enable_autorelabeling(guestfs)

        guestfs_helper.rebuild_rpm_database if @appliance_config.os.name == 'fedora' and @appliance_config.os.version == '11'

        install_additional_packages(guestfs)
        change_configuration(guestfs_helper)
        install_menu_lst(guestfs)

        @linux_helper.recreate_kernel_image(guestfs, ['xenblk', 'xennet']) if @appliance_config.os.name == 'fedora' and @appliance_config.os.version != '11'

        unless @appliance_config.post['ec2'].nil?
          @appliance_config.post['ec2'].each do |cmd|
            guestfs_helper.sh(cmd, :arch => @appliance_config.hardware.arch)
          end
          @log.debug "Post commands from appliance definition file executed."
        else
          @log.debug "No commands specified, skipping."
        end
      end

      @log.info "Image converted to EC2 format."
    end

    def cache_rpms(rpms)
      for name in rpms.keys
        cache_file = "#{@config.dir.src_cache}/#{name}"

        @exec_helper.execute "mkdir -p #{@config.dir.src_cache}"
        @exec_helper.execute "wget #{rpms[name]} -O #{cache_file}" unless File.exist?(cache_file)
      end
    end

    def create_devices(guestfs)
      @log.debug "Creating required devices..."
      guestfs.sh("/sbin/MAKEDEV -d /dev -x console")
      guestfs.sh("/sbin/MAKEDEV -d /dev -x null")
      guestfs.sh("/sbin/MAKEDEV -d /dev -x zero")
      @log.debug "Devices created."
    end

    def disk_device_prefix
      disk = 's'

      case @appliance_config.os.name
        when 'fedora'
          disk = 'xv' if @appliance_config.os.version != '11'
      end

      disk
    end

    def upload_fstab(guestfs)
      @log.debug "Uploading '/etc/fstab' file..."

      fstab_file = @appliance_config.is64bit? ? "#{File.dirname(__FILE__)}/src/fstab_64bit" : "#{File.dirname(__FILE__)}/src/fstab_32bit"

      fstab_data = File.open(fstab_file).read
      fstab_data.gsub!(/#DISK_DEVICE_PREFIX#/, disk_device_prefix)

      fstab = Tempfile.new('fstab')
      fstab << fstab_data
      fstab.flush

      guestfs.upload(fstab.path, "/etc/fstab")

      fstab.close

      @log.debug "'/etc/fstab' file uploaded."
    end

    def install_menu_lst(guestfs)
      @log.debug "Uploading '/boot/grub/menu.lst' file..."
      menu_lst_data = File.open("#{File.dirname(__FILE__)}/src/menu.lst").read

      menu_lst_data.gsub!(/#TITLE#/, @appliance_config.name)
      menu_lst_data.gsub!(/#KERNEL_VERSION#/, @linux_helper.kernel_version(guestfs))
      menu_lst_data.gsub!(/#KERNEL_IMAGE_NAME#/, @linux_helper.kernel_image_name(guestfs))
      menu_lst_data.gsub!(/#DISK_DEVICE_PREFIX#/, disk_device_prefix)

      menu_lst = Tempfile.new('menu_lst')
      menu_lst << menu_lst_data
      menu_lst.flush

      guestfs.upload(menu_lst.path, "/boot/grub/menu.lst")

      menu_lst.close
      @log.debug "'/boot/grub/menu.lst' file uploaded."
    end

    # This fixes issues with Fedora 14 on EC2: https://bugzilla.redhat.com/show_bug.cgi?id=651861#c39
    def enable_nosegneg_flag(guestfs)
      @log.debug "Enabling nosegneg flag..."
      guestfs.sh("echo \"hwcap 1 nosegneg\" > /etc/ld.so.conf.d/libc6-xen.conf")
      guestfs.sh("/sbin/ldconfig")
      @log.debug "Nosegneg enabled."
    end

    # https://issues.jboss.org/browse/BGBUILD-110
    def add_ec2_user(guestfs)
      @log.debug "Adding ec2-user user..."
      guestfs.sh("useradd ec2-user")
      guestfs.sh("echo -e 'ec2-user\tALL=(ALL)\tNOPASSWD: ALL' >> /etc/sudoers")
      @log.debug "User ec2-user added."
    end

    # This corrects SElinux issues
    def enable_autorelabeling(guestfs)
      @log.debug "Enabling SElinux autorelabeling..."
      guestfs.sh("touch /.autorelabel")
      @log.debug "SElinux autorelabeling enabled."
    end

    # enable networking on default runlevels
    def enable_networking(guestfs)
      @log.debug "Enabling networking..."
      guestfs.sh("/sbin/chkconfig network on")
      guestfs.upload("#{File.dirname(__FILE__)}/src/ifcfg-eth0", "/etc/sysconfig/network-scripts/ifcfg-eth0")
      @log.debug "Networking enabled."
    end

    def upload_rc_local(guestfs)
      @log.debug "Uploading '/etc/rc.local' file..."
      rc_local = Tempfile.new('rc_local')
      rc_local << guestfs.read_file("/etc/rc.local") + File.read("#{File.dirname(__FILE__)}/src/rc_local")
      rc_local.flush

      guestfs.upload(rc_local.path, "/etc/rc.local")

      rc_local.close
      @log.debug "'/etc/rc.local' file uploaded."
    end

    def install_additional_packages(guestfs)
      rpms = {}

      begin
        kernel_rpm = KERNELS[@appliance_config.os.name][@appliance_config.os.version][@appliance_config.hardware.base_arch][:rpm]
        rpms[File.basename(kernel_rpm)] = kernel_rpm
      rescue
      end

      cache_rpms(rpms)

      @log.debug "Installing additional packages (#{rpms.keys.join(", ")})..."
      guestfs.mkdir_p("/tmp/rpms")

      for name in rpms.keys
        cache_file = "#{@config.dir.src_cache}/#{name}"
        guestfs.upload(cache_file, "/tmp/rpms/#{name}")
      end

      guestfs.sh("rpm -ivh --nodeps /tmp/rpms/*.rpm")
      guestfs.rm_rf("/tmp/rpms")

      @log.debug "Additional packages installed."
    end

    def change_configuration(guestfs_helper)
      guestfs_helper.augeas do
        # disable password authentication
        set("/etc/ssh/sshd_config", "PasswordAuthentication", "no")

        # disable root login
        set("/etc/ssh/sshd_config", "PermitRootLogin", "no")
      end
    end
  end
end
