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

require 'boxgrinder-build-rpm-based-os-plugin/rpm-based-os-plugin'

module BoxGrinder
  class FedoraPlugin < RPMBasedOSPlugin

    FEDORA_REPOS = {
            "13" => {
                    "base" => {
                            "mirrorlist" => "http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-13&arch=#ARCH#"
                    },
                    "updates" => {
                            "mirrorlist" => "http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f13&arch=#ARCH#"
                    }
            },
            "12" => {
                    "base" => {
                            "mirrorlist" => "http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-12&arch=#ARCH#"
                    },
                    "updates" => {
                            "mirrorlist" => "http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f12&arch=#ARCH#"
                    }
            },
            "11" => {
                    "base" => {
                            "mirrorlist" => "http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-11&arch=#ARCH#"
                    },
                    "updates" => {
                            "mirrorlist" => "http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f11&arch=#ARCH#"
                    }
            },
            "rawhide" => {
                    "base" => {
                            "mirrorlist" => "http://mirrors.fedoraproject.org/mirrorlist?repo=rawhide&arch=#ARCH#"
                    }
            }

    }

    def execute
      build_with_appliance_creator( FEDORA_REPOS )  do |guestfs, guestfs_helper|
        # required when running on Amazon EC2
        @linux_helper.recreate_kernel_image( guestfs, ['xenblk', 'xennet'] )
      end
    end
  end
end