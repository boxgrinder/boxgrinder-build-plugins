require 'boxgrinder-build-s3-delivery-plugin/s3-plugin'
require 'rspec/rspec-config-helper'

module BoxGrinder
  describe S3Plugin do
    include RSpecConfigHelper

    before(:all) do
      @arch = `uname -m`.chomp.strip
    end

    before(:each) do
      @plugin = S3Plugin.new.init(generate_config, generate_appliance_config, :log => Logger.new('/dev/null'), :plugin_info => {:class => BoxGrinder::S3Plugin, :type => :delivery, :name => :s3, :full_name  => "Amazon Simple Storage Service (Amazon S3)", :types => [:s3, :cloudfront, :ami]} )

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
      @plugin.s3_path( '/' ).should == "/"
    end

    it "should generate valid bucket_key" do
      @plugin.ami_bucket_key( "name", "this/is/a/path" ).should == "bucket/this/is/a/path/name/fedora/11/1.0/#{@arch}"
    end

    it "should generate valid bucket_key with mixed slashes" do
      @plugin.ami_bucket_key( "name", "//this/" ).should == "bucket/this/name/fedora/11/1.0/#{@arch}"
    end

    it "should generate valid bucket_key with root path" do
      @plugin.ami_bucket_key( "name", "/" ).should == "bucket/name/fedora/11/1.0/#{@arch}"
    end

    it "should generate valid bucket manifest key" do
      @plugin.bucket_manifest_key( "name", "/a/asd/f/sdf///" ).should == "bucket/a/asd/f/sdf/name/fedora/11/1.0/#{@arch}/name.ec2.manifest.xml"
    end

    it "should fix sha1 sum" do
      ami_manifest = mock('ami_manifest')
      ami_manifest.should_receive(:read).and_return("!sdfrthty54623r2gertyhe(stdin)= wf34r32tewrgeg")

      File.should_receive(:open).with("build/appliances/#{@arch}/fedora/11/full/s3-plugin/ami/full.ec2.manifest.xml").and_return(ami_manifest)

      f = mock('File')
      f.should_receive(:write).with('!sdfrthty54623r2gertyhewf34r32tewrgeg')

      File.should_receive(:open).with("build/appliances/#{@arch}/fedora/11/full/s3-plugin/ami/full.ec2.manifest.xml", 'w').and_yield(f)

      @plugin.fix_sha1_sum
    end

    it "should upload to a S3 bucket" do
      package_helper = mock(PackageHelper)
      package_helper.should_receive(:package).with( {:disk => "adisk"}, {:plugin_info => nil} ).and_return("a_built_package.zip")

      PackageHelper.should_receive(:new).with(@config, @appliance_config, @dir, {:log => @log, :exec_helper => @exec_helper}).and_return(package_helper)

      AWS::S3::Bucket.should_receive(:find).with('bucket').and_return("something")
      File.should_receive(:size).with('a_built_package.zip').and_return(23234566)

       AWS::S3::S3Object.should_receive(:exists?).with('/a_built_package.zip', 'bucket').and_return(false)

      @plugin.should_receive(:open).with('a_built_package.zip').and_return("abc")

      AWS::S3::S3Object.should_receive(:store).with('/a_built_package.zip', 'abc', 'bucket', :access => :private)

      @plugin.upload_to_bucket(:disk => "adisk")
    end
  end
end

