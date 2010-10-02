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

require 'boxgrinder-build-rpm-based-os-plugin/rpm-based-os-plugin'
require 'rspec/rspec-config-helper'

module BoxGrinder
  describe RPMBasedOSPlugin do
    include RSpecConfigHelper

    before(:all) do
      @arch = `uname -m`.chomp.strip
    end

    before(:each) do
      @plugin = RPMBasedOSPlugin.new.init(generate_config, generate_appliance_config, :log => Logger.new('/dev/null'), :plugin_info => { :name => :rpm_based })

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
      @plugin = RPMBasedOSPlugin.new.init(generate_config, generate_appliance_config( "#{RSpecConfigHelper::RSPEC_BASE_LOCATION}/src/appliances/ephemeral-repo.appl" ), :log => Logger.new('/dev/null'), :plugin_info => { :name => :rpm_based })

      guestfs = mock("guestfs")

      guestfs.should_receive(:write_file).once.with("/etc/yum.repos.d/boxgrinder-f12-testing-#{@arch}.repo", "[boxgrinder-f12-testing-#{@arch}]\nname=boxgrinder-f12-testing-#{@arch}\nenabled=1\ngpgcheck=0\nmirrorlist=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-f12&arch=#{@arch}\n", 0)

      @plugin.install_repos( guestfs )
    end
  end
end

