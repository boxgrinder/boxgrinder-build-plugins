require 'boxgrinder-build-rpm-based-os-plugin/rpm-based-os-plugin'
require 'rspec/rspec-config-helper'
require 'rbconfig'

module BoxGrinder
  describe RPMBasedOSPlugin do
    include RSpecConfigHelper

    before(:all) do
      @arch = RbConfig::CONFIG['host_cpu']
    end

    before(:each) do
      @plugin = RPMBasedOSPlugin.new.init(generate_config, generate_appliance_config, :log => Logger.new('/dev/null'))

      @config             = @plugin.instance_variable_get(:@config)
      @appliance_config   = @plugin.instance_variable_get(:@appliance_config)
      @exec_helper        = @plugin.instance_variable_get(:@exec_helper)
      @log                = @plugin.instance_variable_get(:@log)
    end

    it "should install repos" do
      guestfs = mock("guestfs")

      guestfs.should_receive(:write_file).with("/etc/yum.repos.d/cirras.repo", "[cirras]\nname=cirras\nenabled=1\ngpgcheck=0\nbaseurl=http://repo.boxgrinder.org/packages/fedora/11/RPMS/#{@arch}\n", 0)
      guestfs.should_receive(:write_file).with("/etc/yum.repos.d/abc.repo", "[abc]\nname=abc\nenabled=1\ngpgcheck=0\nbaseurl=http://abc\nmirrorlist=http://repo.boxgrinder.org/packages/fedora/11/RPMS/#{@arch}\n", 0)
      guestfs.should_receive(:write_file).with("/etc/yum.repos.d/boxgrinder-f11-testing-#{@arch}.repo", "[boxgrinder-f11-testing-#{@arch}]\nname=boxgrinder-f11-testing-#{@arch}\nenabled=1\ngpgcheck=0\nmirrorlist=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-f11&arch=#{@arch}\n", 0)

      @plugin.install_repos( guestfs )
    end

    it "should not install ephemeral repos" do
      @plugin = RPMBasedOSPlugin.new.init(generate_config, generate_appliance_config( "#{RSpecConfigHelper::RSPEC_BASE_LOCATION}/src/appliances/ephemeral-repo.appl" ), :log => Logger.new('/dev/null'))

      guestfs = mock("guestfs")

      guestfs.should_receive(:write_file).once.with("/etc/yum.repos.d/boxgrinder-f12-testing-#{@arch}.repo", "[boxgrinder-f12-testing-#{@arch}]\nname=boxgrinder-f12-testing-#{@arch}\nenabled=1\ngpgcheck=0\nmirrorlist=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-f12&arch=#{@arch}\n", 0)

      @plugin.install_repos( guestfs )
    end

    it "should return valid kernel version" do
      guestfs = mock("guestfs")
      guestfs.should_receive(:ls).with('/lib/modules').and_return(['2.6.33.6-147.fc13.i686'])
      @plugin.kernel_version( guestfs ).should == '2.6.33.6-147.fc13.i686'
    end

    it "should return valid PAE kernel version" do
      guestfs = mock("guestfs")
      guestfs.should_receive(:ls).with('/lib/modules').and_return(['2.6.33.6-147.fc13.i686.PAE', '2.6.33.6-147.fc13.i686'])
      @plugin.kernel_version( guestfs ).should == '2.6.33.6-147.fc13.i686.PAE'
    end

    it "should recreate initramfs kernel image using dracut and add xennet module" do
      guestfs = mock("guestfs")

      @plugin.should_receive(:kernel_version).and_return('2.6.33.6-147.fc13.i686.PAE')
      guestfs.should_receive(:sh).with('ls -1 /boot | grep initramfs | wc -l').and_return("1 ")

      guestfs.should_receive(:exists).with('/sbin/dracut').and_return(1)
      guestfs.should_receive(:sh).with("/sbin/dracut -f -v --add-drivers xennet /boot/initramfs-2.6.33.6-147.fc13.i686.PAE.img 2.6.33.6-147.fc13.i686.PAE")

      @plugin.recreate_kernel_image( guestfs, ['xennet'] )
    end

    it "should recreate initrd kernel image using mkinitrd and add xenblk and xennet module" do
      guestfs = mock("guestfs")

      @plugin.should_receive(:kernel_version).and_return('2.6.33.6-147.fc13.i686.PAE')
      guestfs.should_receive(:sh).with('ls -1 /boot | grep initramfs | wc -l').and_return(" 0 ")

      guestfs.should_receive(:exists).with('/sbin/dracut').and_return(0)
      guestfs.should_receive(:sh).with("/sbin/mkinitrd -f -v --preload=xenblk --preload=xennet /boot/initrd-2.6.33.6-147.fc13.i686.PAE.img 2.6.33.6-147.fc13.i686.PAE")

      @plugin.recreate_kernel_image( guestfs, ['xenblk', 'xennet'] )
    end

  end
end

