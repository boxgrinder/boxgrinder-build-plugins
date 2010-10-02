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

require 'boxgrinder-build-rpm-based-os-plugin/rpm-based-os-plugin'

module BoxGrinder
  class FedoraPlugin < RPMBasedOSPlugin

    FEDORA_REPOS = {
            "13" => {
                    "base" => {
                            "mirrorlist" => "http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-13&arch=#BASE_ARCH#"
                    },
                    "updates" => {
                            "mirrorlist" => "http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f13&arch=#BASE_ARCH#"
                    }
            },
            "12" => {
                    "base" => {
                            "mirrorlist" => "http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-12&arch=#BASE_ARCH#"
                    },
                    "updates" => {
                            "mirrorlist" => "http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f12&arch=#BASE_ARCH#"
                    }
            },
            "11" => {
                    "base" => {
                            "mirrorlist" => "http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-11&arch=#BASE_ARCH#"
                    },
                    "updates" => {
                            "mirrorlist" => "http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f11&arch=#BASE_ARCH#"
                    }
            },
            "rawhide" => {
                    "base" => {
                            "mirrorlist" => "http://mirrors.fedoraproject.org/mirrorlist?repo=rawhide&arch=#BASE_ARCH#"
                    }
            }
    }

    def execute     
      normalize_packages( @appliance_config.packages.includes )

      build_with_appliance_creator( FEDORA_REPOS )
    end

    def normalize_packages( packages )
      packages << 'passwd'

      case @appliance_config.os.version
        when "13" then
          packages << "system-config-firewall-base"
        when "12" then
          packages << "system-config-firewall-base"
        when "11" then
          packages << "lokkit"
      end

      # kernel_PAE for 32 bit, kernel for 64 bit
      packages.delete('kernel')
      packages.delete('kernel-PAE')

      packages << (@appliance_config.is64bit? ? "kernel" : "kernel-PAE")
    end
  end
end
