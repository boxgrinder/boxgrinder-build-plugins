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
require 'boxgrinder-build-rhel-os-plugin/rhel-plugin'
require 'hashery/opencascade'

module BoxGrinder
  describe RHELPlugin do
    before(:each) do
      @config = mock('Config')
      @appliance_config = mock('ApplianceConfig')

      @appliance_config.stub!(:path).and_return(OpenCascade.new({:build => 'build/path'}))
      @appliance_config.stub!(:name).and_return('full')
      @appliance_config.stub!(:version).and_return(1)
      @appliance_config.stub!(:release).and_return(0)
      @appliance_config.stub!(:os).and_return(OpenCascade.new({:name => 'rhel', :version => '5'}))

      @plugin = RHELPlugin.new.init(@config, @appliance_config, :log => Logger.new('/dev/null'), :plugin_info => {:class => BoxGrinder::RHELPlugin, :type => :os, :name => :rhel, :full_name  => "Red Hat Enterprise Linux", :versions => ['5', '6']})

      @config             = @plugin.instance_variable_get(:@config)
      @appliance_config   = @plugin.instance_variable_get(:@appliance_config)
      @exec_helper        = @plugin.instance_variable_get(:@exec_helper)
      @log                = @plugin.instance_variable_get(:@log)
    end

    it "should add system-config-securitylevel-tui to package list if missing for RHEL 5" do
      packages = []

      @plugin.normalize_packages(packages)

      packages.size.should == 2
      packages[0].should == 'curl'
      packages[1].should == 'system-config-securitylevel-tui'
    end

    it "should build the appliance" do
      @appliance_config.should_receive(:packages).and_return(OpenCascade.new({ :includes => ['kernel'] }))      

      @plugin.should_receive(:adjust_partition_table).ordered
      @plugin.should_receive(:normalize_packages).ordered
      @plugin.should_receive(:build_with_appliance_creator).ordered

      @plugin.execute('file')
    end
  end
end
