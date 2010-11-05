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

require 'boxgrinder-build-ebs-delivery-plugin/ebs-plugin'
require 'rspec/rspec-config-helper'

module BoxGrinder
  describe EBSPlugin do
    include RSpecConfigHelper

    before(:all) do
      @arch = `uname -m`.chomp.strip
    end

    def prepare_plugin
      @plugin = EBSPlugin.new

      yield @plugin if block_given?

      @plugin = @plugin.init(
              generate_config,
              generate_appliance_config,
              :log    => Logger.new('/dev/null'),
              :plugin_info => {:class => BoxGrinder::EBSPlugin, :type => :delivery, :name => :ebs, :full_name  => "Elastic Block Storage"},
              :config_file => "#{File.dirname(__FILE__)}/ebs.yaml"
      )
    end

    describe ".after_init" do
      it "should set default avaibility zone to current one" do
        prepare_plugin do |plugin|
          avaibility_zone = mock('AZ')
          avaibility_zone.should_receive(:string).and_return('avaibility-zone1')

          plugin.should_receive(:open).with('http://169.254.169.254/latest/meta-data/placement/availability-zone').and_return(avaibility_zone)
        end

        @plugin.instance_variable_get(:@plugin_config)['availability_zone'].should == 'avaibility-zone1'
      end

      it "should not set default avaibility zone because we're not on EC2" do
        prepare_plugin do |plugin|
          plugin.should_receive(:open).with('http://169.254.169.254/latest/meta-data/placement/availability-zone').and_raise("Bleh")
        end

        @plugin.instance_variable_get(:@plugin_config)['availability_zone'].should == nil
      end
    end

    it "should get a new free device" do
      prepare_plugin { |plugin| plugin.stub!(:after_init) }

      File.should_receive(:exists?).with("/dev/sdf").and_return(false)
      File.should_receive(:exists?).with("/dev/xvdf").and_return(false)

      @plugin.free_device_suffix.should == "f"
    end

    it "should get a new free device next in order" do
      prepare_plugin { |plugin| plugin.stub!(:after_init) }

      File.should_receive(:exists?).with("/dev/sdf").and_return(false)
      File.should_receive(:exists?).with("/dev/xvdf").and_return(true)
      File.should_receive(:exists?).with("/dev/sdg").and_return(false)
      File.should_receive(:exists?).with("/dev/xvdg").and_return(false)

      @plugin.free_device_suffix.should == "g"
    end

    it "should should return true if on EC2" do
      prepare_plugin { |plugin| plugin.stub!(:after_init) }

      @plugin.should_receive(:open).with("http://169.254.169.254/1.0/meta-data/local-ipv4")

      @plugin.valid_platform?.should == true
    end

    it "should should return true if NOT on EC2" do
      prepare_plugin { |plugin| plugin.stub!(:after_init) }

      @plugin.should_receive(:open).with("http://169.254.169.254/1.0/meta-data/local-ipv4").and_raise("Bleh")

      @plugin.valid_platform?.should == false
    end

  end
end

