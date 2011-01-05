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
require 'boxgrinder-build-local-delivery-plugin/local-plugin'
require 'hashery/opencascade'

module BoxGrinder
  describe LocalPlugin do

    before(:each) do
      @config = mock('Config')
      @appliance_config = mock('ApplianceConfig')

      @appliance_config.stub!(:path).and_return(OpenCascade.new({:build => 'build/path'}))
      @appliance_config.stub!(:name).and_return('appliance')
      @appliance_config.stub!(:version).and_return(1)
      @appliance_config.stub!(:release).and_return(0)
      @appliance_config.stub!(:os).and_return(OpenCascade.new({:name => :fedora, :version => '13'}))
      @appliance_config.stub!(:hardware).and_return(OpenCascade.new({:arch => 'x86_64'}))

      @plugin = LocalPlugin.new.init(@config, @appliance_config,
                                     :log                   => Logger.new('/dev/null'),
                                     :plugin_info           => {:class => BoxGrinder::LocalPlugin, :type => :delivery, :name => :local, :full_name  => "Local file system"},
                                     :previous_deliverables => {:disk => "a_disk.raw"}
      )

      @config             = @plugin.instance_variable_get(:@config)
      @appliance_config   = @plugin.instance_variable_get(:@appliance_config)
      @exec_helper        = @plugin.instance_variable_get(:@exec_helper)
      @log                = @plugin.instance_variable_get(:@log)
      @dir                = @plugin.instance_variable_get(:@dir)
    end

    it "should package and deliver the appliance" do
      @plugin.instance_variable_set(:@plugin_config, {
          'overwrite'   => false,
          'path'        => 'a/path',
          'package'     => true
      })

      FileUtils.should_receive(:mkdir_p).with('a/path')
      package_helper = mock(PackageHelper)
      package_helper.should_receive(:package).with('.', "build/path/local-plugin/tmp/appliance-1.0-fedora-13-x86_64-raw.tgz").and_return("deliverable")

      PackageHelper.should_receive(:new).with(@config, @appliance_config, :log => @log, :exec_helper => @exec_helper).and_return(package_helper)

      @exec_helper.should_receive(:execute).with("cp build/path/local-plugin/tmp/appliance-1.0-fedora-13-x86_64-raw.tgz a/path")
      @plugin.should_receive(:deliverables_exists?).and_return(false)

      @plugin.execute
    end

    it "should not package, but deliver the appliance" do
      @plugin.instance_variable_set(:@plugin_config, {
          'overwrite'   => true,
          'path'        => 'a/path',
          'package'     => false
      })

      FileUtils.should_receive(:mkdir_p).with('a/path')
      PackageHelper.should_not_receive(:new)

      @exec_helper.should_receive(:execute).with("cp build/path/local-plugin/tmp/appliance-1.0-fedora-13-x86_64-raw.tgz a/path")

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
      @plugin.should_receive(:deliverables_exists?).and_return(true)

      @plugin.execute
    end
  end
end

