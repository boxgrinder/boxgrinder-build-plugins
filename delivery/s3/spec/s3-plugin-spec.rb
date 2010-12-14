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
require 'boxgrinder-build-s3-delivery-plugin/s3-plugin'
require 'hashery/opencascade'

module BoxGrinder
  describe S3Plugin do

    before(:each) do
      @config = mock('Config')
      @appliance_config = mock('ApplianceConfig')

      @appliance_config.stub!(:path).and_return(OpenCascade.new({:build => 'build/path'}))
      @appliance_config.stub!(:name).and_return('appliance')
      @appliance_config.stub!(:version).and_return(1)
      @appliance_config.stub!(:release).and_return(0)
      @appliance_config.stub!(:os).and_return(OpenCascade.new({:name => 'fedora', :version => '11'}))
      @appliance_config.stub!(:hardware).and_return(OpenCascade.new({:arch => 'x86_64'}))

      @plugin = S3Plugin.new.init(@config, @appliance_config, :log => Logger.new('/dev/null'), :plugin_info => {:class => BoxGrinder::S3Plugin, :type => :delivery, :name => :s3, :full_name  => "Amazon Simple Storage Service (Amazon S3)", :types => [:s3, :cloudfront, :ami]})

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

    it "should generate valid s3 path" do
      @plugin.s3_path('/').should == "/"
    end

    it "should generate valid bucket_key" do
      @plugin.ami_bucket_key("name", "this/is/a/path").should == "bucket/this/is/a/path/name/fedora/11/1.0/x86_64"
    end

    it "should generate valid bucket_key with mixed slashes" do
      @plugin.ami_bucket_key("name", "//this/").should == "bucket/this/name/fedora/11/1.0/x86_64"
    end

    it "should generate valid bucket_key with root path" do
      @plugin.ami_bucket_key("name", "/").should == "bucket/name/fedora/11/1.0/x86_64"
    end

    it "should generate valid bucket manifest key" do
      @plugin.bucket_manifest_key("name", "/a/asd/f/sdf///").should == "bucket/a/asd/f/sdf/name/fedora/11/1.0/x86_64/name.ec2.manifest.xml"
    end

    it "should fix sha1 sum" do
      ami_manifest = mock('ami_manifest')
      ami_manifest.should_receive(:read).and_return("!sdfrthty54623r2gertyhe(stdin)= wf34r32tewrgeg")

      File.should_receive(:open).with("build/path/s3-plugin/ami/appliance.ec2.manifest.xml").and_return(ami_manifest)

      f = mock('File')
      f.should_receive(:write).with('!sdfrthty54623r2gertyhewf34r32tewrgeg')

      File.should_receive(:open).with("build/path/s3-plugin/ami/appliance.ec2.manifest.xml", 'w').and_yield(f)

      @plugin.fix_sha1_sum
    end

    it "should upload to a S3 bucket" do
      package_helper = mock(PackageHelper)
      package_helper.should_receive(:package).with(".", "build/path/s3-plugin/tmp/appliance-1.0-fedora-11-x86_64-raw.tgz").and_return("a_built_package.zip")

      PackageHelper.should_receive(:new).with(@config, @appliance_config, @dir, {:log => @log, :exec_helper => @exec_helper}).and_return(package_helper)

      s3 = mock(Aws::S3)

      Aws::S3.should_receive(:new).with('access_key', 'secret_access_key', :connection_mode => :single, :logger => @log).and_return(s3)

      key = mock('Key')
      key.should_receive(:exists?).and_return(false)
      key.should_receive(:put).with('abc', 'private')

      bucket = mock('Bucket')
      bucket.should_receive(:key).with("appliance-1.0-fedora-11-x86_64-raw.tgz").and_return(key)

      s3.should_receive(:bucket).with('bucket', true).and_return(bucket)
      s3.should_receive(:close_connection)

      File.should_receive(:size).with("build/path/s3-plugin/tmp/appliance-1.0-fedora-11-x86_64-raw.tgz").and_return(23234566)

      @plugin.should_receive(:open).with("build/path/s3-plugin/tmp/appliance-1.0-fedora-11-x86_64-raw.tgz").and_return("abc")

      @plugin.upload_to_bucket(:disk => "adisk")
    end

    it "should NOT upload to a S3 bucket because file exists" do
      package_helper = mock(PackageHelper)
      package_helper.should_receive(:package).with(".", "build/path/s3-plugin/tmp/appliance-1.0-fedora-11-x86_64-raw.tgz").and_return("a_built_package.zip")

      PackageHelper.should_receive(:new).with(@config, @appliance_config, @dir, {:log => @log, :exec_helper => @exec_helper}).and_return(package_helper)

      s3 = mock(Aws::S3)

      Aws::S3.should_receive(:new).with('access_key', 'secret_access_key', :connection_mode => :single, :logger => @log).and_return(s3)

      key = mock('Key')
      key.should_receive(:exists?).and_return(true)

      bucket = mock('Bucket')
      bucket.should_receive(:key).with("appliance-1.0-fedora-11-x86_64-raw.tgz").and_return(key)

      s3.should_receive(:bucket).with('bucket', true).and_return(bucket)
      s3.should_receive(:close_connection)

      File.should_receive(:size).with("build/path/s3-plugin/tmp/appliance-1.0-fedora-11-x86_64-raw.tgz").and_return(23234566)

      @plugin.upload_to_bucket(:disk => "adisk")
    end
  end
end

