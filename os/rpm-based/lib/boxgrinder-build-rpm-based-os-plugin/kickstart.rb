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

require 'fileutils'
require 'yaml'
require 'erb'

module BoxGrinder

  class Kickstart
    def initialize(config, appliance_config, repos, dir, options = {})
      @config           = config
      @repos            = repos
      @appliance_config = appliance_config
      @dir              = dir
      @log              = options[:log] || Logger.new(STDOUT)

      @kickstart_file   = "#{@dir.base}/#{@appliance_config.name}.ks"
    end

    def create
      template = "#{File.dirname(__FILE__)}/src/appliance.ks.erb"
      kickstart = ERB.new(File.read(template)).result(build_definition.send(:binding))
      File.open( @kickstart_file, 'w') { |f| f.write(kickstart) }

      @kickstart_file
    end

    def build_definition
      definition = {}

      definition['appliance_config']  = @appliance_config
      definition['name']              = @appliance_config.name
      definition['arch']              = @appliance_config.hardware.arch
      definition['appliance_names']   = @appliance_config.appliances
      definition['repos']             = []
      definition['graphical']         = false
      definition['packages']          = []

      definition['packages'] += @appliance_config.packages.includes

      @appliance_config.packages.excludes do |package|
        definition['packages'].push("-#{package}")
      end

      definition['root_password'] = @appliance_config.os.password

      def definition.method_missing(sym, * args)
        self[sym.to_s]
      end

      cost = 40

      definition['partitions'] = {}

      @appliance_config.hardware.partitions.dup.each do |root, partition|
#        case @appliance_config.os.name
#          when 'fedora'
#            case @appliance_config.os.version
#              when '13'
#                default_fs_type = 'ext4'
#              else
#                default_fs_type = 'ext3'
#            end
#          else
#            default_fs_type = 'ext3'
#        end

        default_fs_type = 'ext3'

        partition['type'] = default_fs_type if partition['type'].nil?
        partition['options'] = 'defaults' if partition['options'].nil?
        definition['partitions'][root] = partition
      end

      for repo in valid_repos + @appliance_config.repos
        if repo.keys.include?('mirrorlist')
          urltype = 'mirrorlist'
        else
          urltype = 'baseurl'
        end

        substitutions = {
                /#ARCH#/        => @appliance_config.hardware.arch,
                /#BASE_ARCH#/   => @appliance_config.hardware.base_arch,
                /#OS_VERSION#/  => @appliance_config.os.version,
                /#OS_NAME#/     => @appliance_config.os.name
        }

        url   = repo[urltype]
        name  = repo['name']

        substitutions.each do |key, value|
          url   = url.gsub( key, value )
          name  = name.gsub( key, value )
        end

        repo_def = "repo --name=#{name} --cost=#{cost} --#{urltype}=#{url}"
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
