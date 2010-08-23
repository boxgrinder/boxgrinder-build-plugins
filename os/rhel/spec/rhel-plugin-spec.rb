require 'boxgrinder-build-rhel-os-plugin/rhel-plugin'
require 'rspec/rspec-config-helper'

module BoxGrinder
  describe RHELPlugin do
    include RSpecConfigHelper

    before(:each) do
      @plugin = RHELPlugin.new.init(generate_config, generate_appliance_config, :log => Logger.new('/dev/null'), :plugin_info => {:class => BoxGrinder::EC2Plugin, :type => :platform, :name => :ec2, :full_name  => "Amazon Elastic Compute Cloud (Amazon EC2)"})

      @config             = @plugin.instance_variable_get(:@config)
      @appliance_config   = @plugin.instance_variable_get(:@appliance_config)
      @exec_helper        = @plugin.instance_variable_get(:@exec_helper)
      @log                = @plugin.instance_variable_get(:@log)
    end

    it "should add system-config-securitylevel-tui to package list if missing for RHEL 5" do
      @appliance_config.os.version = '5'

      packages = []

      @plugin.normalize_packages( packages )

      packages.size.should == 1
      packages.first.should == 'system-config-securitylevel-tui'
    end

    it "should build the appliance" do
      @plugin.should_receive( :adjust_partition_table ).ordered
      @plugin.should_receive( :normalize_packages ).ordered
      @plugin.should_receive( :build_with_appliance_creator ).ordered

      @plugin.execute
    end
  end
end

