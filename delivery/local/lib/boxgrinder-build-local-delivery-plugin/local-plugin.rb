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

require 'boxgrinder-build/plugins/base-plugin'

module BoxGrinder
  class LocalPlugin < BasePlugin
    def after_init
      set_default_config_value('overwrite', true)
      set_default_config_value('package', true)
    end

    def execute( type = :local )
      validate_plugin_config( [ 'path' ], 'http://community.jboss.org/docs/DOC-15216' )

      files = []

      if @plugin_config['package']
        files <<  PackageHelper.new(@config, @appliance_config, {:log => @log, :exec_helper => @exec_helper}).package( @previous_deliverables, :plugin_info => @previous_plugin_info )
      else
        files << @previous_deliverables.disk

        [:metadata, :other].each do |deliverable_type|
          @previous_deliverables[deliverable_type].each_value do |file|
            files << file
          end
        end
      end

      if @plugin_config['overwrite'] or !already_delivered?(files)
        FileUtils.mkdir_p @plugin_config['path']

        @log.debug "Copying files to destination..."

        files.each do |file|
          @log.debug "Copying #{file}..."
          FileUtils.cp(file, @plugin_config['path'])
        end
        @log.info "Appliance delivered to #{@plugin_config['path']}."
      else
        @log.info "Appliance already delivered to #{@plugin_config['path']}."
      end
    end

    def already_delivered?(files)
      files.each do |file|
        return false unless File.exists?("#{@plugin_config['path']}/#{File.basename(file)}")
      end
      true
    end
  end
end