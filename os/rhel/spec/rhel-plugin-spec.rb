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

      packages.size.should == 2
      packages[0].should == 'curl'
      packages[1].should == 'system-config-securitylevel-tui'
    end

    it "should build the appliance" do
      @plugin.should_receive( :adjust_partition_table ).ordered
      @plugin.should_receive( :normalize_packages ).ordered
      @plugin.should_receive( :build_with_appliance_creator ).ordered

      @plugin.execute
    end
  end
end

