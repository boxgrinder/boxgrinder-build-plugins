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

require 'yaml'

module BoxGrinder
  class Repo
    def initialize( name, baseurl = nil, mirrorlist = nil )
      @name = name
      @baseurl = baseurl
      @mirrorlist = mirrorlist
    end

    attr_reader :name
    attr_reader :baseurl
    attr_reader :mirrorlist
  end

  class RPMDependencyValidator
    def initialize( config, appliance_config, dir, kickstart_file, options = {} )
      @config           = config
      @appliance_config = appliance_config
      @kickstart_file   = kickstart_file
      @dir              = dir

      @log          = options[:log]         || Logger.new(STDOUT)
      @exec_helper  = options[:exec_helper] || ExecHelper.new( { :log => @log } )

      @yum_config_file = "#{@dir.tmp}/yum.conf"

      # Because we're using repoquery command from our building environment, we must ensure, that our repository
      # names are unique
      @magic_hash = "#{@config.name.downcase.gsub(" ", "_")}-"
    end

    def resolve_packages
      @log.info "Resolving packages added to #{@appliance_config.name} appliance definition file..."

      repos = read_repos_from_kickstart_file
      package_list = generate_package_list
      repo_list = generate_repo_list( repos )

      generate_yum_config( repos )

      invalid_names = invalid_names( repo_list, package_list )

      if invalid_names.size == 0
        @log.info "All additional packages for #{@appliance_config.name} appliance successfully resolved."
      else
        raise "Package#{invalid_names.size > 1 ? "s" : ""} #{invalid_names.join(', ')} for #{@appliance_config.name} appliance not found in repositories. Please check package names in appliance definition file."
      end
    end

    def invalid_names( repo_list, package_list )
      @log.debug "Querying package database..."

      unless @appliance_config.is64bit?
        arches = "i386,i486,i586,i686"
      else
        arches = "x86_64"
      end

      repoquery_output = @exec_helper.execute( "repoquery --quiet --disablerepo=* --enablerepo=#{repo_list} -c #{@yum_config_file} list available #{package_list.join( ' ' )} --nevra --archlist=#{arches},noarch" )

      invalid_names = []

      for name in package_list
        found = false

        repoquery_output.each do |line|
          line = line.strip

          package = line.match( /^([\S]+)-\d+:/ )
          package = package.nil? ? line : package[1]

          if package.size > 0 and name.match( /^#{package.gsub(/[\+]/, '\\+')}/ )
            found = true
          end
        end
        invalid_names += [ name ] unless found
      end

      invalid_names
    end

    def generate_package_list
      packages = []
      for package in @appliance_config.packages.includes
        packages << package unless package.match /^@/
      end
      packages
    end

    def generate_repo_list(repos)
      repo_list = ""

      repos.each do |repo|
        repo_list += "#{@magic_hash}#{repo.name},"
      end

      repo_list = repo_list[0, repo_list.length - 1]
    end

    def read_repos_from_kickstart_file
      repos = `grep -e "^repo" #{@kickstart_file}`
      repo_list = []

      repos.each do |repo_line|
        name = repo_line.match( /--name=([\w\-]+)/ )[1]
        baseurl = repo_line.match( /--baseurl=([\w\-\:\/\.&\?=]+)/ )
        mirrorlist = repo_line.match( /--mirrorlist=([\w\-\:\/\.&\?=]+)/ )

        baseurl = baseurl[1] unless baseurl.nil?
        mirrorlist = mirrorlist[1] unless mirrorlist.nil?

        repo_list.push( Repo.new( name, baseurl, mirrorlist ) )
      end

      repo_list
    end

    def generate_yum_config( repo_list )
      File.open( @yum_config_file, "w") do |f|

        f.puts( "[main]\r\ncachedir=#{Dir.pwd}/#{@dir.tmp}/#{@magic_hash}#{@appliance_config.hardware.arch}-yum-cache/\r\n\r\n" )

        for repo in repo_list
          f.puts( "[#{@magic_hash}#{repo.name}]" )
          f.puts( "name=#{repo.name}" )
          f.puts( "baseurl=#{repo.baseurl}" ) unless repo.baseurl.nil?
          f.puts( "mirrorlist=#{repo.mirrorlist}" ) unless repo.mirrorlist.nil?
          f.puts( "enabled=1" )
          f.puts
        end
      end
    end
  end
end
