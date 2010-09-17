require 'boxgrinder-build-local-delivery-plugin/local-plugin'
require 'rspec/rspec-config-helper'

module BoxGrinder
  describe LocalPlugin do
    include RSpecConfigHelper

    before(:all) do
      @arch = `uname -m`.chomp.strip
    end

    before(:each) do
      @plugin = LocalPlugin.new.init(generate_config, generate_appliance_config,
                                     :log => Logger.new('/dev/null'),
                                     :plugin_info => { :class => BoxGrinder::LocalPlugin, :type => :delivery, :name => :local, :full_name  => "Local file system" },
                                     :previous_deliverables => { :disk => "a_disk.raw"}
      )

      @config             = @plugin.instance_variable_get(:@config)
      @appliance_config   = @plugin.instance_variable_get(:@appliance_config)
      @exec_helper        = @plugin.instance_variable_get(:@exec_helper)
      @log                = @plugin.instance_variable_get(:@log)
      @dir                = @plugin.instance_variable_get(:@dir)
    end

    it "should package and deliver the appliance" do
      @plugin.instance_variable_set(:@plugin_config, @plugin.instance_variable_get(:@plugin_config).merge({
              'path'        => 'a/path',
              })
      )

      package_helper = mock(PackageHelper)
      package_helper.should_receive( :package ).with( {:disk=>"a_disk.raw"}, :plugin_info => nil ).and_return("deliverable")

      PackageHelper.should_receive(:new).with( @config, @appliance_config, @dir, :log => @log, :exec_helper => @exec_helper ).and_return(package_helper)

      @exec_helper.should_receive(:execute).with("cp deliverable a/path")
      @plugin.should_receive(:already_delivered?).with(["deliverable"]).and_return(false)

      @plugin.execute
    end

    it "should not package, but deliver the appliance" do
      @plugin.instance_variable_set(:@plugin_config, {
              'overwrite'   => true,
              'path'        => 'a/path',
              'package'     => false
      })

      PackageHelper.should_not_receive(:new)

      @exec_helper.should_receive(:execute).with("cp a_disk.raw a/path")

      @plugin.execute
    end

    it "should not deliver the package, because it is already delivered" do
      @plugin.instance_variable_set(:@plugin_config, {
              'overwrite'   => false,
              'path'        => 'a/path',
              'package'     => false
      })

      PackageHelper.should_not_receive(:new)

      @exec_helper.should_not_receive(:execute)
      @plugin.should_receive(:already_delivered?).with(["a_disk.raw"]).and_return(true)

      @plugin.execute
    end

    it "should check if files are delivered and return false" do
      @plugin.instance_variable_set(:@plugin_config, {
              'overwrite'   => true,
              'path'        => 'a/path',
              'package'     => false
      })

      File.should_receive(:exists?).with("a/path/abc").and_return(true)
      File.should_receive(:exists?).with("a/path/def").and_return(false)

      @plugin.already_delivered?( ['abc', 'def'] ).should == false
    end

    it "should check if files are delivered and return true" do
      @plugin.instance_variable_set(:@plugin_config, {
              'overwrite'   => true,
              'path'        => 'a/path',
              'package'     => false
      })

      File.should_receive(:exists?).with("a/path/abc").and_return(true)
      File.should_receive(:exists?).with("a/path/def").and_return(true)

      @plugin.already_delivered?( ['abc', 'def'] ).should == true
    end

  end
end

