require 'boxgrinder-build-s3-delivery-plugin/s3-plugin'
require 'rspec/rspec-config-helper'
require 'rbconfig'

module BoxGrinder
  describe S3Plugin do
    include RSpecConfigHelper

    before(:all) do
      @arch = RbConfig::CONFIG['host_cpu']
    end

    before(:each) do
      @plugin = S3Plugin.new.init(generate_config, generate_appliance_config, :log => Logger.new('/dev/null'), :plugin_info => {:class => BoxGrinder::S3Plugin, :type => :delivery, :name => :s3, :full_name  => "Amazon Simple Storage Service (Amazon S3)", :types => [:s3, :cloudfront, :ami]} )

      @config             = @plugin.instance_variable_get(:@config)
      @appliance_config   = @plugin.instance_variable_get(:@appliance_config)
      @exec_helper        = @plugin.instance_variable_get(:@exec_helper)
      @log                = @plugin.instance_variable_get(:@log)

      @plugin_config = {
              'access_key'        => 'access_key',
              'secret_access_key' => 'secret_access_key',
              'bucket'            => 'bucket',
              'account_number'    => '0000-0000-0000',
              'cert_file'         => '/path/to/cert/file',
              'key_file'          => '/path/to/key/file'
      }

      @plugin.instance_variable_set(:@plugin_config, @plugin_config)

    end

    it "should generate valid bucket_key" do
      @plugin.ami_bucket_key( "name", "this/is/a/path" ).should == "bucket/this/is/a/path/name/1.0/#{@arch}"
    end

    it "should generate valid bucket_key with mixed slashes" do
      @plugin.ami_bucket_key( "name", "//this/" ).should == "bucket/this/name/1.0/#{@arch}"
    end

    it "should generate valid bucket_key with root path" do
      @plugin.ami_bucket_key( "name", "/" ).should == "bucket/name/1.0/#{@arch}"
    end

    it "should generate valid bucket manifest key" do
      @plugin.bucket_manifest_key( "name", "/a/asd/f/sdf///" ).should == "bucket/a/asd/f/sdf/name/1.0/#{@arch}/name.ec2.manifest.xml"
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
  end
end

