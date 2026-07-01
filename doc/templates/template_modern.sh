#!/bin/bash
# Copyright (C) 2026 Your Name <your.email@example.com>

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

# REQUIRED METADATA
# long_name: Brief descriptive name shown in web UI
# description: Detailed description of what this plugin checks
# priority: 1-999 (999=critical system failure, 1=informational)
#   900-999: Critical - system can break at any moment
#   800-899: High - core system services at risk
#   600-799: Medium - applications & services
#   400-599: Medium-low - middleware & support
#   200-399: Low - monitoring & logging
#   100-199: Very low - informational
#   1-99: Metadata & development

# OPTIONAL METADATA
# bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=XXXXX
# kb: https://access.redhat.com/solutions/XXXXX

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Main plugin logic
main() {
	# Define files/directories needed for this check
	local config_file="${RISU_ROOT}/etc/example/config.conf"

	# Check if required files exist (automatically exits with RC_SKIPPED if not found)
	is_required_file "${config_file}"

	# Alternatively, for mandatory files that should always exist:
	# is_mandatory_file "${config_file}"  # exits with RC_FAILED if missing

	# Initialize return code
	local rc=${RC_OKAY}

	# Example: Check for a specific condition
	if is_lineinfile "^problematic_setting.*enabled" "${config_file}"; then
		echo "Problematic setting detected in ${config_file}" >&2
		rc=${RC_FAILED}
	fi

	# Example: Check if a service is running (live mode)
	if [[ ${RISU_LIVE} == "1" ]]; then
		if ! is_active "example-service"; then
			echo "example-service is not active" >&2
			rc=${RC_FAILED}
		fi
	else
		# Snapshot mode - check systemctl output files
		if ! is_active "example-service"; then
			echo "example-service is not active in snapshot" >&2
			rc=${RC_FAILED}
		fi
	fi

	# Example: Check RPM package version
	# if is_rpm_over "package-name" "1.2.3"; then
	#     # Package version is greater than 1.2.3
	# fi

	# Example: Parse configuration values
	# local value=$(iniparser "${config_file}" "section_name" "key_name")
	# if [[ "${value}" != "expected_value" ]]; then
	#     echo "Configuration mismatch: expected 'expected_value', got '${value}'" >&2
	#     rc=${RC_FAILED}
	# fi

	exit "${rc}"
}

# Run main function
main "$@"
