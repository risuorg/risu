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

# long_name: Apache Kafka configuration validation
# description: Validates Apache Kafka configuration files and checks for common issues
# priority: 550

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Look for kafka config files
if [[ "x$RISU_LIVE" == "x1" ]]; then
    config_files=$(find /opt/kafka /etc/kafka -name "server.properties" 2>/dev/null)
    zk_config_files=$(find /opt/kafka /etc/kafka -name "zookeeper.properties" 2>/dev/null)
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    config_files=$(find "${RISU_ROOT}/opt/kafka" "${RISU_ROOT}/etc/kafka" -name "server.properties" 2>/dev/null)
    zk_config_files=$(find "${RISU_ROOT}/opt/kafka" "${RISU_ROOT}/etc/kafka" -name "zookeeper.properties" 2>/dev/null)
fi

if [[ -z $config_files ]]; then
    echo "No Kafka configuration files found" >&2
    exit ${RC_SKIPPED}
fi

flag=0

for config_file in $config_files; do
    if [[ ! -f $config_file ]]; then
        continue
    fi

    echo "Checking Kafka config: $config_file" >&2

    # Check broker ID
    broker_id=$(grep "^broker.id" "$config_file" | cut -d'=' -f2)
    if [[ -n $broker_id ]]; then
        echo "Broker ID set to: $broker_id in Kafka config: $config_file" >&2
    else
        echo "Broker ID not configured in Kafka config: $config_file" >&2
        flag=1
    fi

    # Check listeners
    if ! grep -q "^listeners=" "$config_file"; then
        echo "Listeners not configured in Kafka config: $config_file" >&2
        flag=1
    fi

    # Check log directories
    log_dirs=$(grep "^log.dirs" "$config_file" | cut -d'=' -f2)
    if [[ -n $log_dirs ]]; then
        echo "Log directories set to: $log_dirs in Kafka config: $config_file" >&2
    else
        echo "Log directories not configured in Kafka config: $config_file" >&2
        flag=1
    fi

    # Check replication factor
    replication_factor=$(grep "^default.replication.factor" "$config_file" | cut -d'=' -f2)
    if [[ -n $replication_factor ]]; then
        if [[ $replication_factor -lt 3 ]]; then
            echo "Default replication factor is low ($replication_factor) in Kafka config: $config_file" >&2
        fi
    else
        echo "Default replication factor not configured in Kafka config: $config_file" >&2
    fi

    # Check min insync replicas
    min_insync=$(grep "^min.insync.replicas" "$config_file" | cut -d'=' -f2)
    if [[ -n $min_insync ]]; then
        echo "Min insync replicas set to: $min_insync in Kafka config: $config_file" >&2
    else
        echo "Min insync replicas not configured in Kafka config: $config_file" >&2
    fi

    # Check zookeeper connection
    zk_connect=$(grep "^zookeeper.connect" "$config_file" | cut -d'=' -f2)
    if [[ -n $zk_connect ]]; then
        echo "Zookeeper connection set to: $zk_connect in Kafka config: $config_file" >&2
    else
        echo "Zookeeper connection not configured in Kafka config: $config_file" >&2
        flag=1
    fi

    # Check log retention
    log_retention=$(grep "^log.retention.hours" "$config_file" | cut -d'=' -f2)
    if [[ -n $log_retention ]]; then
        echo "Log retention set to: $log_retention hours in Kafka config: $config_file" >&2
    fi

    # Check log segment size
    log_segment_size=$(grep "^log.segment.bytes" "$config_file" | cut -d'=' -f2)
    if [[ -n $log_segment_size ]]; then
        echo "Log segment size set to: $log_segment_size bytes in Kafka config: $config_file" >&2
    fi

    # Check unclean leader election
    if grep -q "^unclean.leader.election.enable=true" "$config_file"; then
        echo "Unclean leader election enabled - data loss possible in Kafka config: $config_file" >&2
        flag=1
    fi

    # Check auto create topics
    if grep -q "^auto.create.topics.enable=true" "$config_file"; then
        echo "Auto create topics enabled in Kafka config: $config_file" >&2
    fi

    # Check compression
    compression=$(grep "^compression.type" "$config_file" | cut -d'=' -f2)
    if [[ -n $compression ]]; then
        echo "Compression type set to: $compression in Kafka config: $config_file" >&2
    fi

    # Check JVM heap size
    if grep -q "^num.network.threads" "$config_file"; then
        network_threads=$(grep "^num.network.threads" "$config_file" | cut -d'=' -f2)
        echo "Network threads set to: $network_threads in Kafka config: $config_file" >&2
    fi

    # Check SSL configuration
    if grep -q "^ssl.keystore.location" "$config_file"; then
        echo "SSL keystore configured in Kafka config: $config_file" >&2
    fi

    # Check SASL configuration
    if grep -q "^sasl.enabled.mechanisms" "$config_file"; then
        echo "SASL authentication configured in Kafka config: $config_file" >&2
    fi
done

# Check Zookeeper configuration
for zk_config in $zk_config_files; do
    if [[ ! -f $zk_config ]]; then
        continue
    fi

    echo "Checking Zookeeper config: $zk_config" >&2

    # Check data directory
    data_dir=$(grep "^dataDir" "$zk_config" | cut -d'=' -f2)
    if [[ -n $data_dir ]]; then
        echo "Zookeeper data directory set to: $data_dir" >&2
    fi

    # Check client port
    client_port=$(grep "^clientPort" "$zk_config" | cut -d'=' -f2)
    if [[ -n $client_port ]]; then
        echo "Zookeeper client port set to: $client_port" >&2
    fi

    # Check max client connections
    max_client_cnxns=$(grep "^maxClientCnxns" "$zk_config" | cut -d'=' -f2)
    if [[ -n $max_client_cnxns ]]; then
        echo "Zookeeper max client connections set to: $max_client_cnxns" >&2
    fi
done

# Check Kafka service on live systems
if [[ "x$RISU_LIVE" == "x1" ]]; then
    if pgrep -f "kafka.Kafka" >/dev/null 2>&1; then
        echo "Kafka service is running" >&2

        # Check if Kafka is responding (requires kafka tools)
        if command -v kafka-topics.sh >/dev/null 2>&1; then
            if kafka-topics.sh --list --zookeeper localhost:2181 >/dev/null 2>&1; then
                echo "Kafka is responding to topic queries" >&2
            fi
        fi
    else
        echo "Kafka service is not running" >&2
    fi

    if pgrep -f "QuorumPeerMain" >/dev/null 2>&1; then
        echo "Zookeeper service is running" >&2
    else
        echo "Zookeeper service is not running" >&2
    fi
fi

if [[ $flag == "1" ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
