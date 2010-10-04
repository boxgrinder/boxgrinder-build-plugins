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

require 'boxgrinder-build/plugins/base-plugin'
require 'AWS'
require 'open-uri'

module BoxGrinder
  class EBSPlugin < BasePlugin

    KERNELS = {
            'us-east-1'        => {
                    'fedora' => {
                            '13' => {
                                    'i386'     => {:aki => 'aki-407d9529'},
                                    'x86_64'   => {:aki => 'aki-427d952b'}
                            }
                    }
            },
            'us-west-1'        => {
                    'fedora' => {
                            '13' => {
                                    'i386'     => {:aki => 'aki-99a0f1dc'},
                                    'x86_64'   => {:aki => 'aki-9ba0f1de'}
                            }
                    }
            },
            'eu-west-1'        => {
                    'fedora' => {
                            '13' => {
                                    'i386'     => {:aki => 'aki-4deec439'},
                                    'x86_64'   => {:aki => 'aki-4feec43b'}
                            }
                    }
            },
            'ap-southeast-1'   => {
                    'fedora' => {
                            '13' => {
                                    'i386'     => {:aki => 'aki-13d5aa41'},
                                    'x86_64'   => {:aki => 'aki-11d5aa43'}
                            }
                    }
            }
    }

    def after_init
      set_default_config_value('availability_zone', 'us-east-1a')
      set_default_config_value('delete_on_termination', true)

      register_supported_os('fedora', ['13'])
    end

    def execute(type = :ebs)
      validate_plugin_config(['access_key', 'secret_access_key', 'account_number'], 'http://community.jboss.org/docs/DOC-15921')

      raise "You try to run this plugin on invalid platform. You can run EBS delivery plugin only on EC2." unless valid_platform?
      raise "You can only convert to EBS type AMI appliances converted to EC2 format. Use '-p ec2' switch. For more info about EC2 plugin see http://community.jboss.org/docs/DOC-15527." unless @previous_plugin_info[:name] == :ec2

      avaibility_zone           = open('http://169.254.169.254/latest/meta-data/placement/availability-zone').string

      raise "You selected #{@plugin_config['availability_zone']} avaibility zone, but your instance is running in #{avaibility_zone} zone. Please change avaibility zone in plugin configuration file to #{avaibility_zone} (see http://community.jboss.org/docs/DOC-15921) or use another instance in #{@plugin_config['availability_zone']} zone to create your EBS AMI." if @plugin_config['availability_zone'] != avaibility_zone

      unless is_supported_os?
        @log.error "EBS delivery plugin supports following operating systems: #{supported_oses}. Your OS is #{@appliance_config.os.name} #{@appliance_config.os.version}."
        return
      end

      ebs_appliance_description = "#{@appliance_config.summary} | Appliance version #{@appliance_config.version}.#{@appliance_config.release} | #{@appliance_config.hardware.arch} architecture"
      ebs_appliance_name        = "#{@appliance_config.name}/#{@appliance_config.os.name}/#{@appliance_config.os.version}/#{@appliance_config.version}.#{@appliance_config.release}/#{@appliance_config.hardware.arch}"

      @ec2                      = AWS::EC2::Base.new(:access_key_id => @plugin_config['access_key'], :secret_access_key => @plugin_config['secret_access_key'])

      @log.debug "Checking if appliance is already registered..."

      ami_id                    = already_registered?(ebs_appliance_name)

      if ami_id
        @log.warn "EBS AMI '#{ebs_appliance_name}' is already registered as '#{ami_id}'."
        return
      end

      @log.info "Creating new EBS volume..."

      size                      = 0

      @appliance_config.hardware.partitions.each_value { |partition| size += partition['size'] }

      # create_volume with 10GB size
      volume_id                 = @ec2.create_volume(:size => size.to_s, :availability_zone => @plugin_config['availability_zone'])['volumeId']

      @log.debug "Volume #{volume_id} created."
      @log.debug "Waiting for EBS volume #{volume_id} to be available..."

      # wait fo volume to be created
      wait_for_volume_status('available', volume_id)

      # get first free device to mount the volume
      suffix                    = free_device_suffix

      @log.trace "Got free device suffix: '#{suffix}'"
      @log.trace "Reading current instance id..."

      # read current instance id
      instance_id               = open('http://169.254.169.254/latest/meta-data/instance-id').string

      @log.trace "Got: #{instance_id}"
      @log.info "Attaching created volume..."

      # attach the volume to current host
      @ec2.attach_volume(:device => "/dev/sd#{suffix}", :volume_id => volume_id, :instance_id => instance_id)

      @log.debug "Waiting for EBS volume to be attached..."

      # wait for volume to be attached
      wait_for_volume_status('in-use', volume_id)

      sleep 5 # let's wait to discover the attached volume by OS 

      @log.info "Copying data to EBS volume..."

      ec2_disk_mount_dir        = "#{@dir.tmp}/ec2-#{rand(9999999999).to_s.center(10, rand(9).to_s)}"
      ebs_disk_mount_dir        = "#{@dir.tmp}/ebs-#{rand(9999999999).to_s.center(10, rand(9).to_s)}"

      FileUtils.mkdir_p(ec2_disk_mount_dir)
      FileUtils.mkdir_p(ebs_disk_mount_dir)

      begin
        ec2_mounts = @image_helper.mount_image(@previous_deliverables.disk, ec2_disk_mount_dir)
      rescue => e
        @log.debug e
        raise "Error while mounting image. See logs for more info"
      end

      @log.debug "Creating filesystem on volume..."

      @image_helper.create_filesystem(device_for_suffix(suffix))
      @exec_helper.execute("mount #{device_for_suffix(suffix)} #{ebs_disk_mount_dir}")

      @log.debug "Syncing files..."

      @image_helper.sync_files(ec2_disk_mount_dir, ebs_disk_mount_dir)

      @log.debug "Adjusting /etc/fstab..."

      adjust_fstab(ebs_disk_mount_dir)

      @exec_helper.execute("umount #{ebs_disk_mount_dir}")
      @image_helper.umount_image(@previous_deliverables.disk, ec2_disk_mount_dir, ec2_mounts)

      FileUtils.rm_rf(ebs_disk_mount_dir)
      FileUtils.rm_rf(ec2_disk_mount_dir)

      @log.debug "Detaching EBS volume..."

      @ec2.detach_volume(:device => "/dev/sd#{suffix}", :volume_id => volume_id, :instance_id => instance_id)

      @log.debug "Waiting for EBS volume to be available..."

      wait_for_volume_status('available', volume_id)

      @log.info "Creating snapshot from EBS volume..."

      snapshot_id               = @ec2.create_snapshot(
              :volume_id   => volume_id,
              :description => ebs_appliance_description)['snapshotId']

      @log.debug "Waiting for snapshot #{snapshot_id} to be completed..."

      wait_for_snapshot_status('completed', snapshot_id)

      @log.debug "Deleting temporary EBS volume..."

      @ec2.delete_volume(:volume_id => volume_id)

      @log.info "Registering image..."

      region                    = avaibility_zone.scan(/((\w+)-(\w+)-(\d+))/).flatten.first
      image_id                  = @ec2.register_image(
              :block_device_mapping   => [{
                                                  :device_name               => '/dev/sda1',
                                                  :ebs_snapshot_id           => snapshot_id,
                                                  :ebs_delete_on_termination => @plugin_config['delete_on_termination']
                                          }],
              :root_device_name       => '/dev/sda1',
              :architecture           => @appliance_config.hardware.base_arch,
              :kernel_id              => KERNELS[region][@appliance_config.os.name][@appliance_config.os.version][@appliance_config.hardware.base_arch][:aki],
              :name                   => ebs_appliance_name,
              :description            => ebs_appliance_description)['imageId']

      @log.info "EBS AMI registered: #{image_id}"
    end

    def sync_files(from_dir, to_dir)
      @log.debug "Syncing files between #{from_dir} and #{to_dir}..."
      @exec_helper.execute "rsync -u -r -a  #{from_dir}/* #{to_dir}"
      @log.debug "Sync finished."
    end

    def already_registered?(name)
      images = @ec2.describe_images(:owner_id => @plugin_config['account_number'].to_s.gsub(/-/, ''))['imagesSet']['item']
      images.each { |image| return image['imageId'] if image['name'] == name }

      false
    end

    def adjust_fstab(ebs_mount_dir)
      @exec_helper.execute("cat #{ebs_mount_dir}/etc/fstab | grep -v '/mnt' | grep -v '/data' | grep -v 'swap' > #{ebs_mount_dir}/etc/fstab.new")
      @exec_helper.execute("mv #{ebs_mount_dir}/etc/fstab.new #{ebs_mount_dir}/etc/fstab")
    end

    def wait_for_snapshot_status(status, snapshot_id)
      snapshot = @ec2.describe_snapshots(:snapshot_id => snapshot_id)['snapshotSet']['item'].first

      unless snapshot['status'] == status
        sleep 2
        wait_for_snapshot_status(status, snapshot_id)
      end
    end

    def wait_for_volume_status(status, volume_id)
      volume = @ec2.describe_volumes(:volume_id => volume_id)['volumeSet']['item'].first

      unless volume['status'] == status
        sleep 2
        wait_for_volume_status(status, volume_id)
      end
    end

    def device_for_suffix(suffix)
      return "/dev/sd#{suffix}" if File.exists?("/dev/sd#{suffix}")
      return "/dev/xvd#{suffix}" if File.exists?("/dev/xvd#{suffix}")

      raise "Not found device for suffix #{suffix}"
    end

    def free_device_suffix
      ("f".."p").each do |suffix|
        return suffix unless File.exists?("/dev/sd#{suffix}") or File.exists?("/dev/xvd#{suffix}")
      end

      raise "Found too many attached devices. Cannot attach EBS volume."
    end

    def valid_platform?
      begin
        open("http://169.254.169.254/1.0/meta-data/local-ipv4")
        true
      rescue
        false
      end
    end
  end
end
