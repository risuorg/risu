#!/bin/bash
# Copyright (C) 2024 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

# long_name: Terraform state file validation
# description: Checks for Terraform state files and validates their integrity
# priority: 400

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Look for terraform state files in common locations
    state_files=$(find /opt /var /home -name "*.tfstate" -o -name "terraform.tfstate" 2>/dev/null)
    terraform_dirs=$(find /opt /var /home -name ".terraform" -type d 2>/dev/null)
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    # Look in sosreport
    state_files=$(find "${RISU_ROOT}" -name "*.tfstate" -o -name "terraform.tfstate" 2>/dev/null)
    terraform_dirs=$(find "${RISU_ROOT}" -name ".terraform" -type d 2>/dev/null)
fi

if [[ -z $state_files && -z $terraform_dirs ]]; then
    echo "No Terraform state files or directories found" >&2
    exit ${RC_SKIPPED}
fi

flag=0

# Check state files
for state_file in $state_files; do
    if [[ -f $state_file ]]; then
        echo "Found Terraform state file: $state_file" >&2

        # Check if state file is valid JSON
        if ! python3 -m json.tool "$state_file" >/dev/null 2>&1; then
            echo "Invalid JSON in state file: $state_file" >&2
            flag=1
        fi

        # Check for sensitive data in state file
        if grep -i "password\|secret\|key\|token" "$state_file" >/dev/null 2>&1; then
            echo "Potential sensitive data found in state file: $state_file" >&2
            flag=1
        fi

        # Check state file permissions
        if [[ "x$RISU_LIVE" == "x1" ]]; then
            perms=$(stat -c "%a" "$state_file")
            if [[ $perms != "600" && $perms != "640" ]]; then
                echo "State file has overly permissive permissions ($perms): $state_file" >&2
                flag=1
            fi
        fi
    fi
done

# Check terraform directories
for tf_dir in $terraform_dirs; do
    if [[ -d $tf_dir ]]; then
        echo "Found Terraform directory: $tf_dir" >&2

        # Check for provider lock file
        if [[ -f "$tf_dir/.terraform.lock.hcl" ]]; then
            echo "Provider lock file found in: $tf_dir" >&2
        else
            echo "No provider lock file found in: $tf_dir" >&2
            flag=1
        fi
    fi
done

if [[ $flag == "1" ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
