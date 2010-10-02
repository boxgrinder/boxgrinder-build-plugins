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

    before(:each) do
      @plugin = EBSPlugin.new.init(generate_config, generate_appliance_config, :log => Logger.new('/dev/null'), :plugin_info => { :class => BoxGrinder::EBSPlugin, :type => :delivery, :name => :ebs, :full_name  => "Elastic Block Storage" })

      @config             = @plugin.instance_variable_get(:@config)
      @appliance_config   = @plugin.instance_variable_get(:@appliance_config)
      @exec_helper        = @plugin.instance_variable_get(:@exec_helper)
      @log                = @plugin.instance_variable_get(:@log)
      @dir                = @plugin.instance_variable_get(:@dir)

      @plugin_config = {
              'access_key'        => 'access_key',
              'secret_access_key' => 'secret_access_key',
              'bucket'            => 'bucket',
              'account_number'    => '0000-0000-0000',
              'cert_file'         => '/path/to/cert/file',
              'key_file'          => '/path/to/key/file',
              'path'              => '/'
      }

      @plugin.instance_variable_set(:@plugin_config, @plugin_config)

    end

    it "should get a new free device" do
      File.should_receive(:exists?).with("/dev/sdf").and_return(false)
      File.should_receive(:exists?).with("/dev/xvdf").and_return(false)

      @plugin.free_device_suffix.should == "f"
    end

    it "should get a new free device next in order" do
      File.should_receive(:exists?).with("/dev/sdf").and_return(false)
      File.should_receive(:exists?).with("/dev/xvdf").and_return(true)
      File.should_receive(:exists?).with("/dev/sdg").and_return(false)
      File.should_receive(:exists?).with("/dev/xvdg").and_return(false)

      @plugin.free_device_suffix.should == "g"
    end

    it "should should return true if on EC2" do
      @plugin.should_receive(:open).with("http://169.254.169.254/1.0/meta-data/local-ipv4")

      @plugin.valid_platform?.should == true
    end

    it "should should return true if NOT on EC2" do
      @plugin.should_receive(:open).with("http://169.254.169.254/1.0/meta-data/local-ipv4").and_raise("Bleh")

      @plugin.valid_platform?.should == false
    end

  end
end

