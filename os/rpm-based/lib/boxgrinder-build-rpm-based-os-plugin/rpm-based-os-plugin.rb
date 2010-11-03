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
require 'boxgrinder-build-rpm-based-os-plugin/kickstart'
require 'boxgrinder-build-rpm-based-os-plugin/rpm-dependency-validator'
require 'boxgrinder-build/helpers/linux-helper'

module BoxGrinder
  class RPMBasedOSPlugin < BasePlugin
    def after_init
      register_deliverable(
              :disk       => "#{@appliance_config.name}-sda.raw",
              :descriptor => "#{@appliance_config.name}.xml"
      )

      @linux_helper = LinuxHelper.new( :log => @log )
    end

    def build_with_appliance_creator( repos = {} )
      kickstart_file = Kickstart.new( @config, @appliance_config, repos, @dir, :log => @log ).create
      RPMDependencyValidator.new( @config, @appliance_config, @dir, kickstart_file, @options ).resolve_packages

      @log.info "Building #{@appliance_config.name} appliance..."

      @exec_helper.execute "appliance-creator -d -v -t #{@dir.tmp} --cache=#{@config.dir.rpms_cache}/#{@appliance_config.path.main} --config #{kickstart_file} -o #{@dir.tmp} --name #{@appliance_config.name} --vmem #{@appliance_config.hardware.memory} --vcpu #{@appliance_config.hardware.cpus}"

      FileUtils.mv( Dir.glob("#{@dir.tmp}/#{@appliance_config.name}/*"), @dir.tmp )
      FileUtils.rm_rf( "#{@dir.tmp}/#{@appliance_config.name}/")

      @image_helper.customize( @deliverables.disk ) do |guestfs, guestfs_helper|
        # TODO is this really needed?
        @log.debug "Uploading '/etc/resolv.conf'..."
        guestfs.upload( "/etc/resolv.conf", "/etc/resolv.conf" )
        @log.debug "'/etc/resolv.conf' uploaded."

        change_configuration( guestfs_helper )
        apply_root_password( guestfs )

        guestfs.sh( "chkconfig firstboot off" ) if guestfs.exists( '/etc/init.d/firstboot' ) != 0

        @log.info "Executing post operations after build..."

        unless @appliance_config.post['base'].nil?
          @appliance_config.post['base'].each do |cmd|
            guestfs_helper.sh( cmd, :arch => @appliance_config.hardware.arch )
          end
          @log.debug "Post commands from appliance definition file executed."
        else
          @log.debug "No commands specified, skipping."
        end

        set_motd( guestfs )

        # TODO remove this (make sure CirrAS build will not break!)
        install_version_files( guestfs )
        install_repos( guestfs )

        yield guestfs, guestfs_helper if block_given?

        @log.info "Post operations executed."
      end

      @log.info "Base image for #{@appliance_config.name} appliance was built successfully."
    end

    def apply_root_password( guestfs )
      @log.debug "Applying root password..."
      guestfs.sh( "/usr/bin/passwd -d root" )
      guestfs.sh( "/usr/sbin/usermod -p '#{@appliance_config.os.password.crypt((0...8).map{65.+(rand(25)).chr}.join)}' root" )
      @log.debug "Password applied."
    end

    def change_configuration( guestfs_helper )
      guestfs_helper.augeas do
        set( '/etc/ssh/sshd_config', 'UseDNS', 'no')
        set( '/etc/sysconfig/selinux', 'SELINUX', 'permissive')
      end
    end

    def install_version_files( guestfs )
      @log.debug "Installing BoxGrinder version files..."
      guestfs.sh( "echo 'BOXGRINDER_VERSION=#{@config.version_with_release}' > /etc/sysconfig/boxgrinder" )
      guestfs.sh( "echo 'APPLIANCE_NAME=#{@appliance_config.name}' >> /etc/sysconfig/boxgrinder" )
      @log.debug "Version files installed."
    end

    def set_motd( guestfs )
      @log.debug "Setting up '/etc/motd'..."
      # set nice banner for SSH
      motd_file = "/etc/init.d/motd"
      guestfs.upload( "#{File.dirname( __FILE__ )}/src/motd.init", motd_file )
      guestfs.sh( "sed -i s/#VERSION#/'#{@appliance_config.version}.#{@appliance_config.release}'/ #{motd_file}" )
      guestfs.sh( "sed -i s/#APPLIANCE#/'#{@appliance_config.name} appliance'/ #{motd_file}" )

      guestfs.sh( "/bin/chmod +x #{motd_file}" )
      guestfs.sh( "/sbin/chkconfig --add motd" )
      @log.debug "'/etc/motd' is nice now."
    end

    def recreate_kernel_image( guestfs, modules = [] )
      @linux_helper.recreate_kernel_image( guestfs, modules )
    end

    def install_repos( guestfs )
      @log.debug "Installing repositories from appliance definition file..."
      @appliance_config.repos.each do |repo|
        if repo['ephemeral']
          @log.debug "Repository '#{repo['name']}' is an ephemeral repo. It'll not be installed in the appliance."
          next
        end

        @log.debug "Installing #{repo['name']} repo..."
        repo_file = File.read( "#{File.dirname( __FILE__ )}/src/base.repo").gsub( /#NAME#/, repo['name'] )

        ['baseurl', 'mirrorlist'].each  do |type|
          repo_file << ("#{type}=#{repo[type]}\n") unless repo[type].nil?
        end

        guestfs.write_file( "/etc/yum.repos.d/#{repo['name']}.repo", repo_file, 0 )
      end
      @log.debug "Repositories installed."
    end

  end
end
