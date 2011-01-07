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

require 'rubygems'
require 'boxgrinder-build-ec2-platform-plugin/ec2-plugin'
require 'hashery/opencascade'

module BoxGrinder
  describe EC2Plugin do
    before(:each) do
      @config = mock('Config')

      @appliance_config = mock('ApplianceConfig')

      @appliance_config.stub!(:path).and_return(OpenCascade.new({:build => 'build/path'}))
      @appliance_config.stub!(:name).and_return('full')
      @appliance_config.stub!(:version).and_return(1)
      @appliance_config.stub!(:release).and_return(0)
      @appliance_config.stub!(:packages).and_return(OpenCascade.new({:includes => ["gcc-c++", "wget"]}))
      @appliance_config.stub!(:os).and_return(OpenCascade.new({:name => 'fedora', :version => '13'}))
      @appliance_config.stub!(:is64bit?).and_return(false)
      @appliance_config.stub!(:post).and_return(OpenCascade.new({:base => ['ls /']}))

      @appliance_config.stub!(:hardware).and_return(
          OpenCascade.new({
                              :partitions =>
                                  {
                                      '/' => {'size' => 2},
                                      '/home' => {'size' => 3},
                                  },
                              :arch => 'i686',
                              :base_arch => 'i386',
                              :cpus => 1,
                              :memory => 256,
                          })
      )

      @plugin = EC2Plugin.new.init(@config, @appliance_config, :log => Logger.new('/dev/null'), :plugin_info => {:class => BoxGrinder::EC2Plugin, :type => :platform, :name => :ec2, :full_name => "Amazon Elastic Compute Cloud (Amazon EC2)"})

      @config = @plugin.instance_variable_get(:@config)
      @appliance_config = @plugin.instance_variable_get(:@appliance_config)
      @image_helper = @plugin.instance_variable_get(:@image_helper)
      @exec_helper = @plugin.instance_variable_get(:@exec_helper)
      @log = @plugin.instance_variable_get(:@log)
    end

    it "should create devices" do
      guestfs = mock("guestfs")

      guestfs.should_receive(:sh).once.with("/sbin/MAKEDEV -d /dev -x console")
      guestfs.should_receive(:sh).once.with("/sbin/MAKEDEV -d /dev -x null")
      guestfs.should_receive(:sh).once.with("/sbin/MAKEDEV -d /dev -x zero")

      @log.should_receive(:debug).once.with("Creating required devices...")
      @log.should_receive(:debug).once.with("Devices created.")

      @plugin.create_devices(guestfs)
    end

    it "should upload fstab" do
      guestfs = mock("guestfs")

      guestfs.should_receive(:upload).once.with(any_args(), "/etc/fstab")

      @log.should_receive(:debug).once.with("Uploading '/etc/fstab' file...")
      @log.should_receive(:debug).once.with("'/etc/fstab' file uploaded.")

      @plugin.upload_fstab(guestfs)
    end

    it "should enable networking" do
      guestfs = mock("guestfs")

      guestfs.should_receive(:sh).once.with("/sbin/chkconfig network on")
      guestfs.should_receive(:upload).once.with(any_args(), "/etc/sysconfig/network-scripts/ifcfg-eth0")

      @log.should_receive(:debug).once.with("Enabling networking...")
      @log.should_receive(:debug).once.with("Networking enabled.")

      @plugin.enable_networking(guestfs)
    end

    it "should upload rc_local" do
      guestfs = mock("guestfs")
      tempfile = mock("tempfile")

      Tempfile.should_receive(:new).with("rc_local").and_return(tempfile)
      File.should_receive(:read).with(any_args()).and_return("with other content")

      guestfs.should_receive(:read_file).once.ordered.with("/etc/rc.local").and_return("content ")
      tempfile.should_receive(:<<).once.ordered.with("content with other content")
      tempfile.should_receive(:flush).once.ordered
      tempfile.should_receive(:path).once.ordered.and_return("path")
      guestfs.should_receive(:upload).once.ordered.with("path", "/etc/rc.local")
      tempfile.should_receive(:close).once.ordered

      @log.should_receive(:debug).once.with("Uploading '/etc/rc.local' file...")
      @log.should_receive(:debug).once.with("'/etc/rc.local' file uploaded.")

      @plugin.upload_rc_local(guestfs)
    end

    it "should change configuration" do
      guestfs_helper = mock("GuestFSHelper")

      guestfs_helper.should_receive(:augeas).and_yield do |block|
        block.should_receive(:set).with("/etc/ssh/sshd_config", "PasswordAuthentication", "no")
        block.should_receive(:set).with("/etc/ssh/sshd_config", "PermitRootLogin", "no")
      end

      @plugin.change_configuration(guestfs_helper)
    end

    it "should install GRUB menu.lst" do
      guestfs = mock("guestfs")

      guestfs.should_receive(:upload).with('path/menu.lst', "/boot/grub/menu.lst")

      linux_helper = mock("LinuxHelper")

      linux_helper.should_receive(:kernel_version).with(guestfs).and_return('2.6.18')
      linux_helper.should_receive(:kernel_image_name).with(guestfs).and_return('vmlinuz')

      @plugin.instance_variable_set(:@linux_helper, linux_helper)

      tempfile = mock(Tempfile)
      tempfile.should_receive(:<<).with("default=0\ntimeout=0\ntitle full\n        root (hd0)\n        kernel /boot/vmlinuz-2.6.18 ro root=/dev/xvda1 rd_NO_PLYMOUTH\n        initrd /boot/vmlinuz-2.6.18.img")
      tempfile.should_receive(:flush)
      tempfile.should_receive(:path).and_return('path/menu.lst')
      tempfile.should_receive(:close)

      Tempfile.should_receive(:new).with('menu_lst').and_return(tempfile)

      @plugin.install_menu_lst(guestfs)
    end

    it "should use xvda disks for Fedora 13" do
      @appliance_config.os.version = '13'
      @plugin.disk_device_prefix.should == 'xv'
    end

    it "should use xvda disks for Fedora 12" do
      @appliance_config.os.version = '12'
      @plugin.disk_device_prefix.should == 'xv'
    end

    it "should enable nosegneg flag" do
      guestfs = mock("guestfs")

      guestfs.should_receive(:sh).with("echo \"hwcap 1 nosegneg\" > /etc/ld.so.conf.d/libc6-xen.conf")
      guestfs.should_receive(:sh).with("/sbin/ldconfig")

      @plugin.enable_nosegneg_flag(guestfs)
    end

    it "should add ec2-user account" do
      guestfs = mock("guestfs")

      guestfs.should_receive(:sh).with("useradd ec2-user")
      guestfs.should_receive(:sh).with("echo -e 'ec2-user\tALL=(ALL)\tNOPASSWD: ALL' >> /etc/sudoers")

      @plugin.add_ec2_user(guestfs)
    end

    describe ".execute" do
      it "should convert the appliance to EC2 format" do
        linux_helper = mock(LinuxHelper)

        LinuxHelper.should_receive(:new).with(:log => @log).and_return(linux_helper)

        @image_helper.should_receive(:create_disk).with("build/path/ec2-plugin/tmp/full.ec2", 10)
        @image_helper.should_receive(:create_filesystem).with("build/path/ec2-plugin/tmp/full.ec2")
        @image_helper.should_receive(:mount_image).twice
        @image_helper.should_receive(:sync_files)
        @image_helper.should_receive(:umount_image).twice

        guestfs = mock("guestfs")
        guestfs_helper = mock("guestfsHelper")

        @image_helper.should_receive(:customize).with("build/path/ec2-plugin/tmp/full.ec2").and_yield(guestfs, guestfs_helper)

        guestfs.should_receive(:upload).with("/etc/resolv.conf", "/etc/resolv.conf")
        @plugin.should_receive(:create_devices).with(guestfs)
        @plugin.should_receive(:upload_fstab).with(guestfs)


        @plugin.should_receive(:enable_networking).with(guestfs)
        @plugin.should_receive(:upload_rc_local).with(guestfs)
        @plugin.should_receive(:enable_nosegneg_flag).with(guestfs)
        @plugin.should_receive(:add_ec2_user).with(guestfs)
        @plugin.should_receive(:change_configuration).with(guestfs_helper)
        @plugin.should_receive(:install_menu_lst).with(guestfs)

        linux_helper.should_not_receive(:recreate_kernel_image)

        @plugin.execute
      end

      it "should recreate kernel image while converting to EC2 format for OS other than fedora" do
        @appliance_config.stub!(:os).and_return(OpenCascade.new({:name => 'rhel', :version => '5'}))
        @appliance_config.stub!(:is64bit?).and_return(true)

        linux_helper = mock(LinuxHelper)

        LinuxHelper.should_receive(:new).with(:log => @log).and_return(linux_helper)

        @image_helper.should_receive(:create_disk).with("build/path/ec2-plugin/tmp/full.ec2", 10)
        @image_helper.should_receive(:create_filesystem).with("build/path/ec2-plugin/tmp/full.ec2")
        @image_helper.should_receive(:mount_image).twice
        @image_helper.should_receive(:sync_files)
        @image_helper.should_receive(:umount_image).twice

        guestfs = mock("guestfs")
        guestfs_helper = mock("guestfsHelper")

        @image_helper.should_receive(:customize).with("build/path/ec2-plugin/tmp/full.ec2").and_yield(guestfs, guestfs_helper)

        guestfs.should_receive(:upload).with("/etc/resolv.conf", "/etc/resolv.conf")
        guestfs.should_receive(:mkdir).with("/data")

        @plugin.should_receive(:create_devices).with(guestfs)
        @plugin.should_receive(:upload_fstab).with(guestfs)


        @plugin.should_receive(:enable_networking).with(guestfs)
        @plugin.should_receive(:upload_rc_local).with(guestfs)
        @plugin.should_receive(:enable_nosegneg_flag).with(guestfs)
        @plugin.should_receive(:add_ec2_user).with(guestfs)
        @plugin.should_receive(:change_configuration).with(guestfs_helper)
        @plugin.should_receive(:install_menu_lst).with(guestfs)

        linux_helper.should_receive(:recreate_kernel_image).with(guestfs, ['xenblk', 'xennet'])

        @plugin.execute
      end
    end
  end
end

