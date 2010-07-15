# JBoss, Home of Professional Open Source
# Copyright 2009, Red Hat Middleware LLC, and individual contributors
# by the @authors tag. See the copyright.txt in the distribution for a
# full listing of individual contributors.
#
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 2.1 of
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

module BoxGrinder
  class EC2Plugin < BasePlugin
    SUPPORTED_OSES = {
            'rhel'    => [ '5' ],
            'centos'  => [ '5' ],
            'fedora'  => [ '11', '13' ]
    }

    REGIONS = {'us_east' => 'url'}

    KERNELS = {
            'fedora' => {
                    '11' => {
                            'i386'     => { :rpm => 'http://repo.oddthesis.org/packages/other/kernel-xen-2.6.21.7-2.fc8.i686.rpm' },
                            'x86_64'   => { :rpm => 'http://repo.oddthesis.org/packages/other/kernel-xen-2.6.21.7-2.fc8.x86_64.rpm' }
                    }
            },
            'centos' => {
                    '5' => {
                            'i386'     => { :rpm => 'http://repo.oddthesis.org/packages/other/kernel-xen-2.6.21.7-2.fc8.i686.rpm' },
                            'x86_64'   => { :rpm => 'http://repo.oddthesis.org/packages/other/kernel-xen-2.6.21.7-2.fc8.x86_64.rpm' }
                    }
            },
            'rhel' => {
                    '5' => {
                            'i386'     => { :rpm => 'http://repo.oddthesis.org/packages/other/kernel-xen-2.6.21.7-2.fc8.i686.rpm' },
                            'x86_64'   => { :rpm => 'http://repo.oddthesis.org/packages/other/kernel-xen-2.6.21.7-2.fc8.x86_64.rpm' }
                    }
            }
    }

    def after_init
      register_deliverable( :disk => "#{@appliance_config.name}.ec2" )
    end

    def supported_os
      supported = ""

      SUPPORTED_OSES.each_key do |os_name|
        supported << "#{os_name}, versions: #{SUPPORTED_OSES[os_name].join(", ")}"
      end

      supported
    end

    def execute
      if File.exists?( @deliverables.disk )
        @log.info "EC2 image for #{@appliance_config.name} appliance already exists, skipping..."
        return
      end

      unless !SUPPORTED_OSES[@appliance_config.os.name].nil? and SUPPORTED_OSES[@appliance_config.os.name].include?(@appliance_config.os.version)
        @log.error "EC2 platform plugin for Linux operating systems supports: #{supported_os}. Your OS is #{@appliance_config.os.name} #{@appliance_config.os.version}."
        return
      end

      @linux_helper = LinuxHelper.new( :log => @log )

      FileUtils.mkdir_p File.dirname( @deliverables.disk )

      @log.info "Converting #{@appliance_config.name} appliance image to EC2 format..."

      begin
        ec2_prepare_disk
        ec2_create_filesystem
      rescue => e
        raise "Error while preparing EC2 disk image. See logs for more info"
      end

      ec2_disk_mount_dir = "#{@dir.tmp}/ec2-#{rand(9999999999).to_s.center(10, rand(9).to_s)}"
      raw_disk_mount_dir = "#{@dir.tmp}/raw-#{rand(9999999999).to_s.center(10, rand(9).to_s)}"

      begin
        ec2_mounts = mount_image( @deliverables.disk, ec2_disk_mount_dir )
        raw_mounts = mount_image( @previous_deliverables.disk, raw_disk_mount_dir )
      rescue => e
        @log.debug e
        raise "Error while mounting image. See logs for more info"
      end

      sync_files(raw_disk_mount_dir, ec2_disk_mount_dir)

      umount_image(@previous_deliverables.disk, raw_disk_mount_dir, raw_mounts)
      umount_image(@deliverables.disk, ec2_disk_mount_dir, ec2_mounts)

      customize(@deliverables.disk) do |guestfs, guestfs_helper|
        # TODO is this really needed?
        @log.debug "Uploading '/etc/resolv.conf'..."
        guestfs.upload( "/etc/resolv.conf", "/etc/resolv.conf" )
        @log.debug "'/etc/resolv.conf' uploaded."

        create_devices(guestfs)
        upload_fstab(guestfs)

        guestfs.mkdir("/data") if @appliance_config.is64bit?

        enable_networking(guestfs)
        upload_rc_local(guestfs)

        guestfs_helper.rebuild_rpm_database

        install_additional_packages(guestfs)
        change_configuration(guestfs)
        install_menu_lst( guestfs )

        unless @appliance_config.post['ec2'].nil?
          @appliance_config.post['ec2'].each do |cmd|
            @log.debug "Executing #{cmd}"
            guestfs.sh( cmd )
          end
          @log.debug "Post commands from appliance definition file executed."
        else
          @log.debug "No commands specified, skipping."
        end
      end

      @log.info "Image converted to EC2 format."
    end

    def ec2_prepare_disk
      # TODO add progress bar?
      # TODO using whole 10GB is fine?
      @log.debug "Preparing disk for EC2 image..."
      @exec_helper.execute "dd if=/dev/zero of=#{@deliverables.disk} bs=1 count=0 seek=#{10 * 1024}M"
      @log.debug "Disk for EC2 image prepared"
    end

    def ec2_create_filesystem
      @log.debug "Creating filesystem..."
      @exec_helper.execute "mkfs.ext3 -F #{@deliverables.disk}"
      @log.debug "Filesystem created"
    end

    def calculate_disk_offsets( disk )
      @log.debug "Calculating offsets for '#{File.basename(disk)}' disk..."
      loop_device = get_loop_device

      @exec_helper.execute("losetup #{loop_device} #{disk}")
      offsets = @exec_helper.execute("parted #{loop_device} 'unit B print' | grep -e '^ [0-9]' | awk '{ print $2 }'").scan(/\d+/)
      @exec_helper.execute("losetup -d #{loop_device}")

      @log.trace "Offsets:\n#{offsets}"

      offsets
    end

    def mount_image(disk, mount_dir)
      offsets = calculate_disk_offsets( disk )

      @log.debug "Mounting image #{File.basename(disk)} in #{mount_dir}..."
      FileUtils.mkdir_p(mount_dir)

      mounts = {}

      offsets.each do |offset|
        loop_device = get_loop_device
        @exec_helper.execute("losetup -o #{offset.to_s} #{loop_device} #{disk}")
        label = @exec_helper.execute("e2label #{loop_device}").strip.chomp
        label = '/' if label == ''
        mounts[label] = loop_device
      end

      @exec_helper.execute("mount #{mounts['/']} -t ext3 #{mount_dir}")

      mounts.each { |mount_point, loop_device| @exec_helper.execute("mount #{loop_device} -t ext3 #{mount_dir}/#{mount_point}") unless mount_point == '/' }

      @log.trace "Mounts:\n#{mounts}"

      mounts
    end

    def umount_image(disk, mount_dir, mounts)
      @log.debug "Unmounting image '#{File.basename(disk)}'..."

      mounts.each { |mount_point, loop_device| @exec_helper.execute("umount -d #{loop_device}") unless mount_point == '/' }

      @exec_helper.execute("umount -d #{mounts['/']}")

      FileUtils.rm_rf(mount_dir)
    end


    def sync_files(from_dir, to_dir)
      @log.debug "Syncing files between #{from_dir} and #{to_dir}..."
      @exec_helper.execute "rsync -u -r -a  #{from_dir}/* #{to_dir}"
      @log.debug "Sync finished."
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

      fstab_data = File.open( fstab_file ).read
      fstab_data.gsub!( /#DISK_DEVICE_PREFIX#/, disk_device_prefix )

      fstab = Tempfile.new('fstab')
      fstab << fstab_data
      fstab.flush

      guestfs.upload(fstab.path, "/etc/fstab")

      fstab.close

      @log.debug "'/etc/fstab' file uploaded."
    end

    def install_menu_lst( guestfs )
      @log.debug "Uploading '/boot/grub/menu.lst' file..."
      menu_lst_data = File.open( "#{File.dirname( __FILE__ )}/src/menu.lst" ).read

      menu_lst_data.gsub!( /#TITLE#/, @appliance_config.name )
      menu_lst_data.gsub!( /#KERNEL_VERSION#/, @linux_helper.kernel_version( guestfs ) )
      menu_lst_data.gsub!( /#KERNEL_IMAGE_NAME#/, @linux_helper.kernel_image_name( guestfs ) )
      menu_lst_data.gsub!( /#DISK_DEVICE_PREFIX#/, disk_device_prefix )

      menu_lst = Tempfile.new('menu_lst')
      menu_lst << menu_lst_data
      menu_lst.flush

      guestfs.upload(menu_lst.path, "/boot/grub/menu.lst")

      menu_lst.close
      @log.debug "'/boot/grub/menu.lst' file uploaded."
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
      rpms = {
              "ec2-ami-tools.noarch.rpm" => "http://s3.amazonaws.com/ec2-downloads/ec2-ami-tools.noarch.rpm"
      }

      begin
        kernel_rpm = KERNELS[@appliance_config.os.name][@appliance_config.os.version][@appliance_config.hardware.arch][:rpm]
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

    def change_configuration(guestfs)
      @log.debug "Changing configuration files using augeas..."
      guestfs.aug_init("/", 0)
      # disable password authentication
      guestfs.aug_set("/files/etc/ssh/sshd_config/PasswordAuthentication", "no")
      guestfs.aug_save
      @log.debug "Augeas changes saved."
    end

    def get_loop_device
      begin
        loop_device = @exec_helper.execute("losetup -f 2>&1").strip
      rescue
        raise "No free loop devices available, please free at least one. See 'losetup -d' command."
      end

      loop_device
    end
  end
end