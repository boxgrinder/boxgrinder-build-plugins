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
require 'boxgrinder-build-rpm-based-os-plugin/rpm-based-os-plugin'

module BoxGrinder
  describe RPMBasedOSPlugin do
    before(:each) do
      @config = mock('Config')
      @appliance_config = mock('ApplianceConfig')

      @appliance_config.stub!(:path).and_return(OpenCascade.new({:build => 'build/path'}))
      @appliance_config.stub!(:name).and_return('full')
      @appliance_config.stub!(:version).and_return(1)
      @appliance_config.stub!(:release).and_return(0)
      @appliance_config.stub!(:os).and_return(OpenCascade.new({:name => 'fedora', :version => '11'}))

      @plugin = RPMBasedOSPlugin.new.init(@config, @appliance_config, :log => Logger.new('/dev/null'), :plugin_info => {:name => :rpm_based})

      @config             = @plugin.instance_variable_get(:@config)
      @appliance_config   = @plugin.instance_variable_get(:@appliance_config)
      @exec_helper        = @plugin.instance_variable_get(:@exec_helper)
      @log                = @plugin.instance_variable_get(:@log)
    end

    it "should install repos" do
      @appliance_config.should_receive(:repos).and_return(
          [
              {'name' => 'cirras', 'baseurl' => "http://repo.boxgrinder.org/packages/fedora/11/RPMS/x86_64"},
              {'name' => 'abc', 'baseurl' => 'http://abc', 'mirrorlist' => "http://abc.org/packages/fedora/11/RPMS/x86_64"},
          ])

      guestfs = mock("guestfs")
      guestfs.should_receive(:write_file).with("/etc/yum.repos.d/cirras.repo", "[cirras]\nname=cirras\nenabled=1\ngpgcheck=0\nbaseurl=http://repo.boxgrinder.org/packages/fedora/11/RPMS/x86_64\n", 0)
      guestfs.should_receive(:write_file).with("/etc/yum.repos.d/abc.repo", "[abc]\nname=abc\nenabled=1\ngpgcheck=0\nbaseurl=http://abc\nmirrorlist=http://abc.org/packages/fedora/11/RPMS/x86_64\n", 0)

      @plugin.install_repos(guestfs)
    end

    it "should not install ephemeral repos" do
      @appliance_config.should_receive(:repos).and_return(
          [
              {'name' => 'abc', 'baseurl' => 'http://abc', 'mirrorlist' => "http://abc.org/packages/fedora/11/RPMS/x86_64"},
              {'name' => 'cirras', 'baseurl' => "http://repo.boxgrinder.org/packages/fedora/11/RPMS/x86_64", 'ephemeral' => true}
          ])

      guestfs = mock("guestfs")
      guestfs.should_receive(:write_file).with("/etc/yum.repos.d/abc.repo", "[abc]\nname=abc\nenabled=1\ngpgcheck=0\nbaseurl=http://abc\nmirrorlist=http://abc.org/packages/fedora/11/RPMS/x86_64\n", 0)

      @plugin.install_repos(guestfs)
    end
  end
end

