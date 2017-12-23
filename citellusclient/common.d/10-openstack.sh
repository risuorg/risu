#!/usr/bin/env bash
# Description: This script contains common functions to be used by citellus plugins
#
# Copyright (C) 2017  Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Helper script to define location of various files.

mapping_os_versions(){
    if [[ -z $rhos_release || -z $os_project_name ]] ; then
      declare -A osproject_2_osv
      declare -A nova_versions
      releases=$(curl -s https://releases.openstack.org/ |
        awk '/^<tr.*class="doc">/ {
        t=gensub(/^<tr.*class="doc">(\w+).*$/, "\\1", "g", $0); print t }' |
        tac)
      counter="1"
      for release in $releases; do
        osproject_2_osv[$release]=$counter
        nova_version=$(
          curl -s https://releases.openstack.org/${release,,}/index.html |
          awk 'BEGIN {RS="<tr"} /class="std/ && />nova</ {
          print gensub(/<td>([0-9]+\.[0-9]+).*<\/td>/, "\\1", "g", $7)}')
        nova_versions[$nova_version]=$release
        counter=$[ $counter + 1 ]
      done
      os_release=$(is_rpm openstack-nova-common | awk 'BEGIN {FS="."} ;
        {print gensub(/openstack-nova-common-([0-9]+).*/, "\\1", $1)"."$2}')
      os_project_name=${nova_versions[$os_release]}
      rhos_release=$((${osproject_2_osv[$os_project_name]}-4))

      # Exporting these to global to save from running the above mapping
      export os_project_name
      export rhos_release
    fi

    case $1 in
      version) echo $rhos_release ;;
      name) echo $os_project_name ;;
    esac
}

discover_osp_version(){
    mapping_os_versions version
}

name_osp_version(){
    mapping_os_versions name
}
