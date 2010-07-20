require 'boxgrinder-build-fedora-os-plugin/fedora-plugin'
require 'rspec/rspec-config-helper'
require 'rbconfig'

module BoxGrinder
  describe FedoraPlugin do
    include RSpecConfigHelper

    before(:all) do
      @arch = RbConfig::CONFIG['host_cpu']
    end

    before(:each) do
      @plugin = FedoraPlugin.new.init(generate_config, generate_appliance_config, :log => Logger.new('/dev/null'), :plugin_info => { :name => :fedora })

      @config             = @plugin.instance_variable_get(:@config)
      @appliance_config   = @plugin.instance_variable_get(:@appliance_config)
      @exec_helper        = @plugin.instance_variable_get(:@exec_helper)
      @log                = @plugin.instance_variable_get(:@log)
    end

    it "should normalize the kernel" do
      packages = ['abc', 'def', 'kernel']

      @plugin.normalize_kernel( packages )

      packages.should == (@arch == 'i386' ? ['abc', 'def', 'kernel-PAE'] : ['abc', 'def', 'kernel'])
    end
  end
end

