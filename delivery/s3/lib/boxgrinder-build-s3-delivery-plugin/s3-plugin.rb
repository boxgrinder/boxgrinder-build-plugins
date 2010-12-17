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
require 'boxgrinder-build/plugins/base-plugin'
require 'boxgrinder-build/helpers/package-helper'
require 'AWS'
require 'aws'

module BoxGrinder
  class S3Plugin < BasePlugin

    AMI_OSES = {
            'fedora'  => [ '13', '14' ],
            'centos'  => [ '5' ],
            'rhel'    => [ '5' ]
    }

    KERNELS = {
            'us_east' => {
                    'fedora' => {
                            '14' => {
                                    'i386'     => { :aki => 'aki-407d9529' },
                                    'x86_64'   => { :aki => 'aki-427d952b' }
                            },
                            '13' => {
                                    'i386'     => { :aki => 'aki-407d9529' },
                                    'x86_64'   => { :aki => 'aki-427d952b' }
                            }
                    },
                    'centos' => {
                            '5' => {
                                    'i386'     => { :aki => 'aki-a71cf9ce', :ari => 'ari-a51cf9cc' },
                                    'x86_64'   => { :aki => 'aki-b51cf9dc', :ari => 'ari-b31cf9da' }
                            }
                    },
                    'rhel' => {
                            '5' => {
                                    'i386'     => { :aki => 'aki-a71cf9ce', :ari => 'ari-a51cf9cc' },
                                    'x86_64'   => { :aki => 'aki-b51cf9dc', :ari => 'ari-b31cf9da' }
                            }
                    }
            }
    }

    def after_init
      set_default_config_value('overwrite', false)
      set_default_config_value('path', '/')
      set_default_config_value('url', 'http://s3.amazonaws.com')

      @ami_build_dir  = "#{@dir.base}/ami"
      @ami_manifest   = "#{@ami_build_dir}/#{@appliance_config.name}.ec2.manifest.xml"
    end

    # TODO: remove this from here, use base-plugin os info
    def supported_os
      supported = ""

      AMI_OSES.each_key do |os_name|
        supported << "#{os_name}, versions: #{AMI_OSES[os_name].join(", ")}"
      end

      supported
    end

    def execute( type = :ami )
      validate_plugin_config(['bucket', 'access_key', 'secret_access_key'], 'http://community.jboss.org/docs/DOC-15217')

      case type
        when :s3
          upload_to_bucket(@previous_deliverables)
        when :cloudfront
          upload_to_bucket(@previous_deliverables, 'public-read')
        when :ami
          validate_plugin_config(['cert_file', 'key_file', 'account_number'], 'http://community.jboss.org/docs/DOC-15217')

          @plugin_config['account_number'] = @plugin_config['account_number'].to_s.gsub(/-/, '')

          @ec2 = AWS::EC2::Base.new(:access_key_id => @plugin_config['access_key'], :secret_access_key => @plugin_config['secret_access_key'])

          unless AMI_OSES[@appliance_config.os.name].include?(@appliance_config.os.version)
            @log.error "You cannot convert selected image to AMI because of unsupported operating system: #{@appliance_config.os.name} #{@appliance_config.os.version}. Supported systems: #{supported_os}."
            return
          end

          unless image_already_uploaded?
            bundle_image( @previous_deliverables )
            fix_sha1_sum
            upload_image
          else
            @log.debug "AMI for #{@appliance_config.name} appliance already uploaded, skipping..."
          end

          register_image
      end
    end

    # https://jira.jboss.org/browse/BGBUILD-34
    def fix_sha1_sum
      ami_manifest = File.open( @ami_manifest ).read
      ami_manifest.gsub!( '(stdin)= ', '' )

      File.open( @ami_manifest, "w" ) {|f| f.write( ami_manifest ) }
    end

    def upload_to_bucket(previous_deliverables, permissions = 'private')
      register_deliverable(
          :package => "#{@appliance_config.name}-#{@appliance_config.version}.#{@appliance_config.release}-#{@appliance_config.os.name}-#{@appliance_config.os.version}-#{@appliance_config.hardware.arch}-#{current_platform}.tgz"
      )

      # quick and dirty workaround to use @deliverables[:package] later in code
      FileUtils.mv( @target_deliverables[:package], @deliverables[:package] ) if File.exists?( @target_deliverables[:package] )

      PackageHelper.new(@config, @appliance_config, @dir, {:log => @log, :exec_helper => @exec_helper}).package( File.dirname(previous_deliverables[:disk]), @deliverables[:package] )

      @s3 = Aws::S3.new( @plugin_config['access_key'], @plugin_config['secret_access_key'], :connection_mode => :single, :logger => @log )

      bucket = @s3.bucket( @plugin_config['bucket'], true )

      remote_path = "#{s3_path( @plugin_config['path'] )}#{File.basename(@deliverables[:package])}"
      size_b      = File.size(@deliverables[:package])

      key = bucket.key( remote_path.gsub(/^\//, '').gsub(/\/\//, '') )

      unless key.exists? or @plugin_config['overwrite']
        @log.info "Uploading #{File.basename(@deliverables[:package])} (#{size_b/1024/1024}MB) to '#{@plugin_config['bucket']}#{remote_path}' path..."
        key.put( open(@deliverables[:package]), permissions )
        @log.info "Appliance #{@appliance_config.name} uploaded to S3."
      else
        @log.info "File '#{@plugin_config['bucket']}#{remote_path}' already uploaded, skipping."
      end

      @s3.close_connection
    end

    def bundle_image( deliverables )
      return if File.exists?( @ami_build_dir )

      @log.info "Bundling AMI..."

      FileUtils.mkdir_p( @ami_build_dir )

      aki = "--kernel #{KERNELS['us_east'][@appliance_config.os.name][@appliance_config.os.version][@appliance_config.hardware.base_arch][:aki]}"
      ari = KERNELS['us_east'][@appliance_config.os.name][@appliance_config.os.version][@appliance_config.hardware.base_arch][:ari].nil? ? "" : "--ramdisk #{KERNELS['us_east'][@appliance_config.os.name][@appliance_config.os.version][@appliance_config.hardware.base_arch][:ari]}"

      @exec_helper.execute("euca-bundle-image --ec2cert #{File.dirname(__FILE__)}/src/cert-ec2.pem -i #{deliverables[:disk]} #{aki} #{ari} -c #{@plugin_config['cert_file']} -k #{@plugin_config['key_file']} -u #{@plugin_config['account_number']} -r #{@appliance_config.hardware.base_arch} -d #{@ami_build_dir}")

      @log.info "Bundling AMI finished."
    end

    def image_already_uploaded?

      begin
        bucket = @s3.bucket( @plugin_config['bucket'] )
        bucket.keys
      rescue
        return false
      end

      manifest_location = bucket_manifest_key(@appliance_config.name, @plugin_config['path'])
      manifest_location = manifest_location[manifest_location.index("/") + 1, manifest_location.length]

      return true if bucket.key( manifest_location ).exists?

      false
    end

    def upload_image
      @log.info "Uploading #{@appliance_config.name} AMI to bucket '#{@plugin_config['bucket']}'..."

      @exec_helper.execute("euca-upload-bundle -U #{@plugin_config['url']} -b #{ami_bucket_key(@appliance_config.name, @plugin_config['path'])} -m #{@ami_manifest} -a #{@plugin_config['access_key']} -s #{@plugin_config['secret_access_key']}")
    end

    def register_image
      info  = ami_info(@appliance_config.name, @plugin_config['path'])

      if info
        @log.info "Image is registered under id: #{info.imageId}"
      else
        info = @ec2.register_image(:image_location => bucket_manifest_key(@appliance_config.name, @plugin_config['path']))
        @log.info "Image successfully registered under id: #{info.imageId}."
      end
    end

    def ami_info( appliance_name, path )
      ami_info = nil

      images = @ec2.describe_images( :owner_id => @plugin_config['account_number'] ).imagesSet

      return nil if images.nil?

      for image in images.item do
        ami_info = image if (image.imageLocation.eql?( bucket_manifest_key( appliance_name, path ) ))
      end

      ami_info
    end

    def s3_path( path )
      return path if path == '/'

      "/#{path.gsub(/^(\/)*/, '').gsub(/(\/)*$/, '')}/"
    end

    def ami_bucket_key( appliance_name, path )
      "#{@plugin_config['bucket']}#{s3_path( path )}#{appliance_name}/#{@appliance_config.os.name}/#{@appliance_config.os.version}/#{@appliance_config.version}.#{@appliance_config.release}/#{@appliance_config.hardware.arch}"
    end

    def bucket_manifest_key( appliance_name, path )
      "#{ami_bucket_key( appliance_name, path )}/#{appliance_name}.ec2.manifest.xml"
    end
  end
end
