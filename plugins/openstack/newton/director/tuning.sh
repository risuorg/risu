#!/bin/bash

# Copyright (C) 2017   Robin Cernin (rcernin@redhat.com)

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

# Checking Tuned Undercloud options
# Ref: https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/10/html-single/director_installation_and_usage/#sect-Tuning_the_Undercloud
REFNAME="Checking Tuning options"

# Checking /etc/heat/heat.conf

grep_file "${DIRECTORY}/etc/heat/heat.conf" "^[ \t]*max_resources_per_stack.*=.*-1"
grep_file "${DIRECTORY}/etc/heat/heat.conf" "^[ \t]*num_engine_workers.*=.*4"

# Checking /etc/my.cnf.d/server.cnf

# Number of simultaneous connections to the database. The recommended
# value is 4096. 
grep_file "${DIRECTORY}/etc/my.cnf.d/server.cnf" "^[ \t]*max_connections.*=.*4096"

# The size in bytes of a memory pool the database uses to store data
# dictionary information and other internal data structures. The default
# is usually 8M and an ideal value is 20M for the undercloud. 
grep_file "${DIRECTORY}/etc/my.cnf.d/server.cnf" "^[ \t]*innodb_additional_mem_pool_size.*=.*20M"

# The size in bytes of the buffer pool, the memory area where the 
# database caches table and index data. The default is usually 128M and 
# an ideal value is 1000M for the undercloud. 
grep_file "${DIRECTORY}/etc/my.cnf.d/server.cnf" "^[ \t]*innodb_buffer_pool_size.*=.*1000M"

# Controls the balance between strict ACID compliance for commit
# operations, and higher performance that is possible when commit-related
# I/O operations are rearranged and done in batches. Set to 1. 
grep_file "${DIRECTORY}/etc/my.cnf.d/server.cnf" "^[ \t]*innodb_flush_log_at_trx_commit.*=.*1"

# The length of time in seconds a database transaction waits for a row
# lock before giving up. Set to 50. 
grep_file "${DIRECTORY}/etc/my.cnf.d/server.cnf" "^[ \t]*innodb_lock_wait_timeout.*=.*50"

# This variable controls how to delay INSERT, UPDATE, and DELETE
# operations when purge operations are lagging. Set to 10000. 
grep_file "${DIRECTORY}/etc/my.cnf.d/server.cnf" "^[ \t]*innodb_max_purge_lag.*=.*10000"

# The limit of concurrent operating system threads. Ideally, provide at
# least two threads for each CPU and disk resource. For example, if
# using a quad-core CPU and a single disk, use 10 threads. 
grep_file ${DIRECTORY}"/etc/my.cnf.d/server.cnf" "^[ \t]*innodb_thread_concurrency.*=.*2"

# Sometimes the director might not have enough resources to perform
# concurrent node provisioning. The default is 10 nodes at the same time.
# To reduce the number of concurrent nodes, set the max_concurrent_builds
# parameter in /etc/nova/nova.conf
grep_file "${DIRECTORY}/etc/nova/nova.conf" "^[ \t]*max_concurrent_builds.*=.*5"
