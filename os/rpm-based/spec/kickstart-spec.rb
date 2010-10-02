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

require 'boxgrinder-build-rpm-based-os-plugin/kickstart'
require 'rspec/rspec-config-helper'

module BoxGrinder
  describe Kickstart do
    include RSpecConfigHelper

    before(:all) do
      @arch = `uname -m`.chomp.strip
    end

    def prepare_kickstart
      @kickstart = Kickstart.new( generate_config, generate_appliance_config, {}, OpenHash.new(:base => 'a/base/dir') )
    end

    it "should prepare valid definition" do
      prepare_kickstart

      definition = @kickstart.build_definition

      definition['repos'].size.should == 3

      definition['repos'][0].should == "repo --name=cirras --cost=40 --baseurl=http://repo.boxgrinder.org/packages/fedora/11/RPMS/#{@arch}"
      definition['repos'][1].should == "repo --name=abc --cost=41 --mirrorlist=http://repo.boxgrinder.org/packages/fedora/11/RPMS/#{@arch}"
      definition['repos'][2].should == "repo --name=boxgrinder-f11-testing-#{@arch} --cost=42 --mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-f11&arch=#{@arch}"

      definition['packages'].size.should == 2
      definition['packages'].should == ["gcc-c++", "wget"]

      definition['root_password'].should == "boxgrinder"
      definition['fstype'].should == "ext3"
    end
  end
end

