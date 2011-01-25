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
# TODO remove this when it'll become not necessary
# quick fix for old active_support require issue in EPEL 5
require 'active_support/basic_object'
require 'active_support/duration'

module BoxGrinder
  describe S3Plugin do

    before(:each) do
      @config = mock('Config')
      @config.stub!(:delivery_config).and_return({})
      plugins = mock('Plugins')
      plugins.stub!(:[]).with('s3').and_return({})
      @config.stub!(:[]).with(:plugins).and_return(plugins)

      @appliance_config = mock('ApplianceConfig')

      @appliance_config.stub!(:path).and_return(OpenCascade.new({:build => 'build/path'}))
      @appliance_config.stub!(:name).and_return('appliance')
      @appliance_config.stub!(:version).and_return(1)
      @appliance_config.stub!(:release).and_return(0)
      @appliance_config.stub!(:os).and_return(OpenCascade.new({:name => 'fedora', :version => '14'}))
      @appliance_config.stub!(:hardware).and_return(OpenCascade.new({:arch => 'x86_64', :base_arch => 'x86_64'}))

      @plugin = S3Plugin.new.init(@config, @appliance_config, :log => Logger.new('/dev/null'), :plugin_info => {:class => BoxGrinder::S3Plugin, :type => :delivery, :name => :s3, :full_name => "Amazon Simple Storage Service (Amazon S3)", :types => [:s3, :cloudfront, :ami]})

      @config = @plugin.instance_variable_get(:@config)
      @appliance_config = @plugin.instance_variable_get(:@appliance_config)
      @exec_helper = @plugin.instance_variable_get(:@exec_helper)
      @log = @plugin.instance_variable_get(:@log)
      @dir = @plugin.instance_variable_get(:@dir)

      @plugin_config = @plugin.instance_variable_get(:@plugin_config).merge(
          {
              'access_key' => 'access_key',
              'secret_access_key' => 'secret_access_key',
              'bucket' => 'bucket',
              'account_number' => '0000-0000-0000',
              'cert_file' => '/path/to/cert/file',
              'key_file' => '/path/to/key/file',
              'path' => '/'
          }
      )

      @plugin.instance_variable_set(:@plugin_config, @plugin_config)

    end

    it "should register all operating systems with specific versions" do
      supportes_oses = @plugin.instance_variable_get(:@supported_oses)

      supportes_oses.size.should == 3
      supportes_oses.keys.sort.should == ['centos', 'fedora', 'rhel']
      supportes_oses['centos'].should == ['5']
      supportes_oses['rhel'].should == ['5', '6']
      supportes_oses['fedora'].should == ['13', '14']
    end

    it "should generate valid s3 path" do
      @plugin.s3_path('/').should == ""
    end

    describe ".ami_key" do
      it "should generate valid ami_key" do
        @plugin.ami_key("name", "this/is/a/path").should == "this/is/a/path/name/fedora/14/1.0/x86_64"
      end

      it "should generate valid ami_key with mixed slashes" do
        @plugin.ami_key("name", "//this/").should == "this/name/fedora/14/1.0/x86_64"
      end

      it "should generate valid ami_key with root path" do
        @plugin.ami_key("name", "/").should == "name/fedora/14/1.0/x86_64"
      end

      it "should generate valid ami_key with snapshot number two" do
        @plugin_config.merge!('snapshot' => true)
        bucket = mock('Bucket')
        bucket.should_receive(:keys).twice

        key = mock('Key')
        key.should_receive(:exists?).and_return(true)

        key1 = mock('Key')
        key1.should_receive(:exists?).and_return(false)

        bucket.should_receive(:key).with("name/fedora/14/1.0-SNAPSHOT-1/x86_64/").and_return(key)
        bucket.should_receive(:key).with("name/fedora/14/1.0-SNAPSHOT-2/x86_64/").and_return(key1)

        @plugin.should_receive(:bucket).twice.with(false).and_return(bucket)

        @plugin.ami_key("name", "/").should == "name/fedora/14/1.0-SNAPSHOT-2/x86_64"
      end

      it "should generate valid ami_key with snapshot when bucket doesn't exists" do
        @plugin_config.merge!('snapshot' => true)
        @plugin.should_receive(:bucket).with(false).and_raise('ABC')
        @plugin.ami_key("name", "/").should == "name/fedora/14/1.0-SNAPSHOT-1/x86_64"
      end
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
      package_helper.should_receive(:package).with(".", "build/path/s3-plugin/tmp/appliance-1.0-fedora-14-x86_64-raw.tgz").and_return("a_built_package.zip")

      PackageHelper.should_receive(:new).with(@config, @appliance_config, :log => @log, :exec_helper => @exec_helper).and_return(package_helper)

      s3 = mock(Aws::S3)
      @plugin.instance_variable_set(:@s3, s3)

      key = mock('Key')
      key.should_receive(:exists?).and_return(false)
      key.should_receive(:put).with('abc', 'private', :server => 's3.amazonaws.com')

      bucket = mock('Bucket')
      bucket.should_receive(:key).with("appliance-1.0-fedora-14-x86_64-raw.tgz").and_return(key)

      @plugin.should_receive(:bucket).with(true, 'private').and_return(bucket)

      s3.should_receive(:close_connection)

      File.should_receive(:size).with("build/path/s3-plugin/tmp/appliance-1.0-fedora-14-x86_64-raw.tgz").and_return(23234566)

      @plugin.should_receive(:open).with("build/path/s3-plugin/tmp/appliance-1.0-fedora-14-x86_64-raw.tgz").and_return("abc")

      @plugin.upload_to_bucket(:disk => "adisk")
    end

    it "should NOT upload to a S3 bucket because file exists" do
      package_helper = mock(PackageHelper)
      package_helper.should_receive(:package).with(".", "build/path/s3-plugin/tmp/appliance-1.0-fedora-14-x86_64-raw.tgz").and_return("a_built_package.zip")

      PackageHelper.should_receive(:new).with(@config, @appliance_config, :log => @log, :exec_helper => @exec_helper).and_return(package_helper)

      s3 = mock(Aws::S3)
      @plugin.instance_variable_set(:@s3, s3)

      key = mock('Key')
      key.should_receive(:exists?).and_return(true)

      bucket = mock('Bucket')
      bucket.should_receive(:key).with("appliance-1.0-fedora-14-x86_64-raw.tgz").and_return(key)

      @plugin.should_receive(:bucket).with(true, 'private').and_return(bucket)

      s3.should_receive(:close_connection)

      File.should_receive(:size).with("build/path/s3-plugin/tmp/appliance-1.0-fedora-14-x86_64-raw.tgz").and_return(23234566)

      @plugin.upload_to_bucket(:disk => "adisk")
    end

    it "should bundle the image" do
      File.should_receive(:exists?).with('build/path/s3-plugin/ami').and_return(false)
      @exec_helper.should_receive(:execute).with(/euca-bundle-image --ec2cert (.*)src\/cert-ec2\.pem -i a\/path\/to\/disk\.ec2 --kernel aki-427d952b  -c \/path\/to\/cert\/file -k \/path\/to\/key\/file -u 0000-0000-0000 -r x86_64 -d build\/path\/s3-plugin\/ami/)
      @plugin.bundle_image(:disk => "a/path/to/disk.ec2")
    end

    it "should bundle the image for centos 5 anf choose right kernel and ramdisk" do
      @appliance_config.stub!(:os).and_return(OpenCascade.new({:name => 'centos', :version => '5'}))

      File.should_receive(:exists?).with('build/path/s3-plugin/ami').and_return(false)
      @exec_helper.should_receive(:execute).with(/euca-bundle-image --ec2cert (.*)src\/cert-ec2\.pem -i a\/path\/to\/disk\.ec2 --kernel aki-b51cf9dc --ramdisk ari-b31cf9da -c \/path\/to\/cert\/file -k \/path\/to\/key\/file -u 0000-0000-0000 -r x86_64 -d build\/path\/s3-plugin\/ami/)
      @plugin.bundle_image(:disk => "a/path/to/disk.ec2")
    end

    it "should bundle the image for centos 5 anf choose right kernel and ramdisk" do
      @appliance_config.stub!(:os).and_return(OpenCascade.new({:name => 'centos', :version => '5'}))
      @plugin.instance_variable_get(:@plugin_config).merge!({'region' => 'us-west-1'})

      File.should_receive(:exists?).with('build/path/s3-plugin/ami').and_return(false)
      @exec_helper.should_receive(:execute).with(/euca-bundle-image --ec2cert (.*)src\/cert-ec2\.pem -i a\/path\/to\/disk\.ec2 --kernel aki-813667c4 --ramdisk ari-833667c6 -c \/path\/to\/cert\/file -k \/path\/to\/key\/file -u 0000-0000-0000 -r x86_64 -d build\/path\/s3-plugin\/ami/)
      @plugin.bundle_image(:disk => "a/path/to/disk.ec2")
    end

    describe ".execute" do
      it "should create AMI" do
        @plugin.instance_variable_set(:@previous_deliverables, {:disk => 'a/disk'})

        @plugin.should_receive(:validate_plugin_config).with(["bucket", "access_key", "secret_access_key"], "http://community.jboss.org/docs/DOC-15217")
        @plugin.should_receive(:validate_plugin_config).with(["cert_file", "key_file", "account_number"], "http://community.jboss.org/docs/DOC-15217")
        @plugin.should_receive(:ami_key).with("appliance", "/").and_return('ami/key')
        @plugin.should_receive(:s3_object_exists?).with("ami/key/appliance.ec2.manifest.xml").and_return(false)
        @plugin.should_receive(:bundle_image).with(:disk => 'a/disk')
        @plugin.should_receive(:fix_sha1_sum)
        @plugin.should_receive(:upload_image)
        @plugin.should_receive(:register_image)

        @plugin.execute(:ami)
      end

      it "should not upload AMI because it's already there" do
        @plugin.should_receive(:validate_plugin_config).with(["bucket", "access_key", "secret_access_key"], "http://community.jboss.org/docs/DOC-15217")
        @plugin.should_receive(:validate_plugin_config).with(["cert_file", "key_file", "account_number"], "http://community.jboss.org/docs/DOC-15217")
        @plugin.should_receive(:ami_key).with("appliance", "/").and_return('ami/key')
        @plugin.should_receive(:s3_object_exists?).with("ami/key/appliance.ec2.manifest.xml").and_return(true)
        @plugin.should_not_receive(:upload_image)
        @plugin.should_receive(:register_image)

        @plugin.execute(:ami)
      end

      it "should upload AMI even if it's already there because we want a snapshot" do
        @plugin_config.merge!('snapshot' => true)

        @plugin.should_receive(:validate_plugin_config).with(["bucket", "access_key", "secret_access_key"], "http://community.jboss.org/docs/DOC-15217")
        @plugin.should_receive(:validate_plugin_config).with(["cert_file", "key_file", "account_number"], "http://community.jboss.org/docs/DOC-15217")

        @plugin.should_receive(:ami_key).with("appliance", "/").and_return('ami/key')
        @plugin.should_receive(:s3_object_exists?).with("ami/key/appliance.ec2.manifest.xml").and_return(true)
        @plugin.should_receive(:bundle_image).with({})
        @plugin.should_receive(:fix_sha1_sum)
        @plugin.should_receive(:upload_image).with("ami/key")
        @plugin.should_receive(:register_image).with("ami/key/appliance.ec2.manifest.xml")

        @plugin.execute(:ami)
      end

      it "should upload image to s3" do
        @plugin.instance_variable_set(:@previous_deliverables, :disk => 'a/disk')
        @plugin.should_receive(:upload_to_bucket).with({:disk => 'a/disk'})
        @plugin.execute(:s3)
      end

      it "should upload image to cludfront" do
        @plugin.instance_variable_set(:@previous_deliverables, {:disk => 'a/disk'})
        @plugin.should_receive(:upload_to_bucket).with({:disk => 'a/disk'}, 'public-read')
        @plugin.execute(:cloudfront)
      end
    end

    describe ".bucket" do
      it "should create the bucket" do
        @plugin_config.merge!('region' => 'ap-southeast-1')
        s3 = mock(Aws::S3)
        Aws::S3.should_receive(:new).with("access_key", "secret_access_key", :connection_mode => :single, :logger => @log, :server=>"s3-ap-southeast-1.amazonaws.com").and_return(s3)
        s3.should_receive(:bucket).with("bucket", true, "private", :location => "ap-southeast-1")
        @plugin.bucket
      end

      it "should not create the bucket" do
        @plugin_config.merge!('region' => 'ap-southeast-1')
        s3 = mock(Aws::S3)
        Aws::S3.should_receive(:new).with("access_key", "secret_access_key", :connection_mode => :single, :logger => @log, :server=>"s3-ap-southeast-1.amazonaws.com").and_return(s3)
        s3.should_receive(:bucket).with("bucket", false, "private", :location => "ap-southeast-1")
        @plugin.bucket(false)
      end
    end

    describe ".upload_image" do
      it "should upload image for default region" do
        @plugin.should_receive(:bucket)
        @exec_helper.should_receive(:execute).with("euca-upload-bundle -U http://s3.amazonaws.com -b bucket/ami/key -m build/path/s3-plugin/ami/appliance.ec2.manifest.xml -a access_key -s secret_access_key")
        @plugin.upload_image("ami/key")
      end

      it "should upload image for us-west-1 region" do
        @plugin_config.merge!('region' => 'us-west-1')

        @plugin.should_receive(:bucket)
        @exec_helper.should_receive(:execute).with("euca-upload-bundle -U http://s3-us-west-1.amazonaws.com -b bucket/ami/key -m build/path/s3-plugin/ami/appliance.ec2.manifest.xml -a access_key -s secret_access_key")
        @plugin.upload_image("ami/key")
      end
    end

    describe ".register_image" do
      before(:each) do
        @ami_info = mock('AmiInfo')
        @ami_info.should_receive(:imageId).and_return('ami-1234')

        @ec2 = mock("EC2")
        @ec2.stub(:register_image).and_return(@ami_info)
        @plugin.instance_variable_set(:@ec2, @ec2)
      end

      context "when the AMI has not been registered" do
        before(:each) do
          @plugin.stub(:ami_info)
        end

        it "should register the AMI" do
          @plugin.should_receive(:ami_info).with("ami/manifest/key")
          @ec2.should_receive(:register_image).with(:image_location => "bucket/ami/manifest/key").and_return(@ami_info)

          @plugin.register_image("ami/manifest/key")
        end

        it "should report the region where the ami is registed" do
          @plugin.instance_variable_get(:@plugin_config)['region'] = 'a-region'
          @plugin.instance_variable_get(:@log).should_receive(:info).with(/a-region/)

          @plugin.register_image("ami/manifest/key")
        end
      end

      context "when the AMI has been registered" do
        before(:each) do
          @plugin.stub(:ami_info).and_return(@ami_info)
        end

        it "should not register the AMI" do
          @plugin.should_receive(:ami_info).with("ami/manifest/key").and_return(@ami_info)
          @ec2.should_not_receive(:register_image)

          @plugin.register_image("ami/manifest/key")
        end

        it "should report the region where the ami is registed" do
          @plugin.instance_variable_get(:@plugin_config)['region'] = 'a-region'
          @plugin.instance_variable_get(:@log).should_receive(:info).with(/a-region/)

          @plugin.register_image("ami/manifest/key")
        end
      end
    end
  end
end
