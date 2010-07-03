# JBoss, Home of Professional Open Source
# Copyright 2009, Red Hat Middleware LLC, and individual contributors
# by the @authors tag. See the copyright.txt in the distribution for a
# full listing of individual contributors.
#
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 2.1 of
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

require 'fileutils'
require 'yaml'
require 'erb'

module BoxGrinder

  class Kickstart

    def initialize(config, appliance_config, repos, options = {})
      @config           = config
      @repos            = repos
      @appliance_config = appliance_config
      @log              = options[:log] || Logger.new(STDOUT)
    end

    def create
      FileUtils.mkdir_p @appliance_config.path.dir.raw.build

      template = "#{File.dirname(__FILE__)}/src/appliance.ks.erb"
      kickstart = ERB.new(File.read(template)).result(build_definition.send(:binding))
      File.open(@appliance_config.path.file.raw.kickstart, 'w') { |f| f.write(kickstart) }
    end

    def build_definition
      definition = {}

      definition['appliance_config']  = @appliance_config

      #definition['partitions']      = @appliance_config.hardware.partitions.values
      definition['name']            = @appliance_config.name
      definition['arch']            = @appliance_config.hardware.arch
      definition['appliance_names'] = @appliance_config.appliances
      definition['repos']           = []

#      appliance_definition          = @image_config.definition
#
#      if SUPPORTED_DESKTOP_TYPES.include?( appliance_definition['desktop'] )
#        definition['graphical'] = true
#
#        # default X package groups
#        definition['packages'] = [ "@base-x", "@base", "@core", "@fonts", "@input-methods", "@admin-tools", "@dial-up", "@hardware-support", "@printing" ]
#
#        #selected desktop environment
#        definition['packages'] += [ "@#{appliance_definition['desktop']}-desktop" ]
#      else
#        definition['graphical'] = false
#        definition['packages']  = []
#      end

      definition['graphical'] = false
      definition['packages']  = []

      definition['packages'] += @appliance_config.packages.includes

      @appliance_config.packages.excludes do |package|
        definition['packages'].push("-#{package}")
      end

      # defautlt filesystem
      definition['fstype'] = "ext3"

      # fix for F12; this is needed because of selinux management in appliance-creator
      if @appliance_config.os.name.eql?("fedora")
        definition['packages'].push("kernel", "passwd")
        case @appliance_config.os.version.to_s
          when "12" then
            definition['packages'].push "system-config-firewall-base"
          # default filesystem for fedora 12
          #definition['fstype'] = "ext4"
          when "11" then
            definition['packages'].push "lokkit"
        end
      end

      definition['root_password'] = @appliance_config.os.password

      def definition.method_missing(sym, * args)
        self[sym.to_s]
      end

      cost = 40

      for repo in valid_repos + @appliance_config.repos
        if repo.keys.include?('mirrorlist')
          urltype = 'mirrorlist'
        else
          urltype = 'baseurl'
        end

        url = repo[urltype].gsub(/#ARCH#/, @appliance_config.hardware.arch).gsub(/#OS_VERSION#/, @appliance_config.os.version).gsub(/#OS_NAME#/, @appliance_config.os.name)

        repo_def = "repo --name=#{repo['name']} --cost=#{cost} --#{urltype}=#{url}"
        repo_def += " --excludepkgs=#{repo['excludes'].join(',')}" unless repo['excludes'].nil? or repo['excludes'].empty?

        definition['repos'] << repo_def

        cost += 1
      end

      definition
    end

    def valid_repos
      os_repos = @repos[@appliance_config.os.version]

      repos = Array.new

      for type in ["base", "updates"]
        unless os_repos.nil? or os_repos[type].nil?

          mirrorlist = os_repos[type]['mirrorlist']
          baseurl = os_repos[type]['baseurl']

          name = "#{@appliance_config.os.name}-#{@appliance_config.os.version}-#{type}"

          if mirrorlist.nil?
            repos.push({"name" => name, "baseurl" => baseurl})
          else
            repos.push({"name" => name, "mirrorlist" => mirrorlist})
          end
        end
      end

      repos
    end
  end

end
