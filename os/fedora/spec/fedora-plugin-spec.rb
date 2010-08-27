require 'boxgrinder-build-fedora-os-plugin/fedora-plugin'
require 'rspec/rspec-config-helper'

module BoxGrinder
  describe FedoraPlugin do
    include RSpecConfigHelper

    before(:all) do
      @arch = `uname -m`.chomp.strip
    end

    before(:each) do
      @plugin = FedoraPlugin.new.init(generate_config, generate_appliance_config, :log => Logger.new('/dev/null'), :plugin_info => { :name => :fedora })

      @config             = @plugin.instance_variable_get(:@config)
      @appliance_config   = @plugin.instance_variable_get(:@appliance_config)
      @exec_helper        = @plugin.instance_variable_get(:@exec_helper)
      @log                = @plugin.instance_variable_get(:@log)
    end

    it "should normalize packages for i386" do
      packages = ['abc', 'def', 'kernel']

      @appliance_config.hardware.arch = "i386"
      @plugin.normalize_packages( packages )
      packages.should == ['abc', 'def', 'passwd', 'lokkit', 'kernel-PAE']
    end

    it "should normalize packages for x86_64" do
      packages = ['abc', 'def', 'kernel']

      @appliance_config.hardware.arch = "x86_64"
      @plugin.normalize_packages( packages )
      packages.should == ['abc', 'def', 'passwd', 'lokkit', 'kernel']
    end

  end
end

