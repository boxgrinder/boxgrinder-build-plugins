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

    FEDORA_REPOS = {
            "11" => {
                    "base"    => {"mirrorlist" => "http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-11&arch=#BASE_ARCH#"},
                    "updates" => {"mirrorlist" => "http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f11&arch=#BASE_ARCH#"}
            }
    }

    before(:all) do
      @arch = `uname -m`.chomp.strip
      @base_arch = @arch.eql?("x86_64") ? "x86_64" : "i386"
    end

    def prepare_kickstart(repos = {})
      @kickstart = Kickstart.new(generate_config, generate_appliance_config, repos, OpenHash.new(:base => 'a/base/dir'))
    end

    describe ".build_definition" do
      it "should prepare valid definition" do
        prepare_kickstart(FEDORA_REPOS)

        definition = @kickstart.build_definition

        definition['repos'].size.should == 5

        definition['repos'][0].should == "repo --name=fedora-11-base --cost=40 --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-11&arch=#{@base_arch}"
        definition['repos'][1].should == "repo --name=fedora-11-updates --cost=41 --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f11&arch=#{@base_arch}"
        definition['repos'][2].should == "repo --name=cirras --cost=42 --baseurl=http://repo.boxgrinder.org/packages/fedora/11/RPMS/#{@arch}"
        definition['repos'][3].should == "repo --name=abc --cost=43 --mirrorlist=http://repo.boxgrinder.org/packages/fedora/11/RPMS/#{@arch}"
        definition['repos'][4].should == "repo --name=boxgrinder-f11-testing-#{@arch} --cost=44 --mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-f11&arch=#{@arch}"

        definition['packages'].size.should == 2
        definition['packages'].should == ["gcc-c++", "wget"]

        definition['root_password'].should == "boxgrinder"
        definition['partitions'].size.should == 2
        definition['partitions']['/']['size'].should == 2
        definition['partitions']['/home']['size'].should == 3
      end

      it "should prepare valid definition without default repos" do
        prepare_kickstart(FEDORA_REPOS)

        appliance_config = @kickstart.instance_variable_get(:@appliance_config)
        appliance_config.default_repos = false

        definition = @kickstart.build_definition

        definition['repos'].size.should == 3

        definition['repos'][0].should == "repo --name=cirras --cost=40 --baseurl=http://repo.boxgrinder.org/packages/fedora/11/RPMS/#{@arch}"
        definition['repos'][1].should == "repo --name=abc --cost=41 --mirrorlist=http://repo.boxgrinder.org/packages/fedora/11/RPMS/#{@arch}"
        definition['repos'][2].should == "repo --name=boxgrinder-f11-testing-#{@arch} --cost=42 --mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-f11&arch=#{@arch}"

        definition['packages'].size.should == 2
        definition['packages'].should == ["gcc-c++", "wget"]

        definition['root_password'].should == "boxgrinder"
        definition['partitions'].size.should == 2
        definition['partitions']['/']['size'].should == 2
        definition['partitions']['/home']['size'].should == 3
      end
    end
  end
end

