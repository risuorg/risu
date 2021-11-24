#!/bin/bash
set -euo pipefail
: ${HEALTHCHECK_DEBUG:=0}
if [ $HEALTHCHECK_DEBUG -ne 0 ]; then
    set -x
    exec 3>&1
else
    exec 3>/dev/null
fi
: ${HEALTHCHECK_CURL_MAX_TIME:=10}
: ${HEALTHCHECK_CURL_USER_AGENT:=curl-healthcheck}
: ${HEALTHCHECK_CURL_WRITE_OUT:='\n%{http_code} %{remote_ip}:%{remote_port} %{time_total} seconds\n'}
: ${HEALTHCHECK_CURL_OUTPUT:='/dev/null'}

get_user_from_process() {
    process=$1

    # This helps to capture the actual pid running the process
    pid=$(pgrep -d ',' -f $process)

    # Here, we use the embedded `ps' filter capabilities, and remove the
    # output header. We ensure we get the user for the selected PIDs only.
    # In order to ensure we don't get multiple lines, we truncate it with `head'
    ps -h -q${pid} -o user | head -n1
}

healthcheck_curl() {
    if [ $# == 0 ]; then
        echo 'healthcheck_curl: no parameter provided'
        return 1
    fi
    export NSS_SDB_USE_CACHE=no
    curl -g -k -q -s -S --fail -o "${HEALTHCHECK_CURL_OUTPUT}" \
        --max-time "${HEALTHCHECK_CURL_MAX_TIME}" \
        --user-agent "${HEALTHCHECK_CURL_USER_AGENT}" \
        --write-out "${HEALTHCHECK_CURL_WRITE_OUT}" \
        "$@" || return 1
}

healthcheck_port() {
    process=$1

    shift 1
    args=$@
    puser=$(get_user_from_process $process)
    ports=${args// /,}
    pids=$(pgrep -d ',' -f $process)
    # First match exits - usually TCP and "sudo TCP" are enough.
    # `sudo' is needed, as in some cases even root can get a "permission denied"
    # on some file descriptors (case for heat_manager for example)
    # UDP support is needed for octavia manager (UDP:5555).
    lsof -n -w -P -a -iTCP:${ports} -p${pids} >&3 2>&1 ||
        sudo -u $puser lsof -n -w -P -a -iTCP:${ports} -p${pids} >&3 2>&1 ||
        lsof -w -P -a -iUDP:${ports} -p${pids} >&3 2>&1 ||
        sudo -u $puser lsof -n -w -P -a -iUDP:${ports} -p${pids} >&3 2>&1
}

healthcheck_listen() {
    process=$1

    shift 1
    args=$@
    ports=${args// /,}
    pids=$(pgrep -d ',' -f $process)
    lsof -n -w -P -a -p${pids} -iTCP:${ports} -s TCP:LISTEN >&3 2>&1
}

healthcheck_socket() {
    process=$1
    socket=$2
    pids=$(pgrep -d ',' -f $process)

    lsof -n -Fc -Ua -p${pids} $socket >&3 2>&1
}

healthcheck_file_modification() {
    file_path=$1
    limit_seconds=$2

    # if the file doesn't exist, return 1
    if [ ! -f $file_path ]; then
        echo "${file_path} does not exist for file modification check"
        return 1
    fi
    curr_time=$(date +%s)
    last_mod=$(stat -c '%Y' $file_path)
    limit_epoch=$((curr_time - limit_seconds))
    if [ ${limit_epoch} -gt ${last_mod} ]; then
        return 1
    fi
}

get_config_val() {
    crudini --get "$1" "$2" "$3" 2>/dev/null || echo "$4"
}

# apachectl -S is slightly harder to parse and doesn't say if the vhost is serving SSL
get_url_from_vhost() {
    vhost_file=$1
    if test -n "${vhost_file}" && test -r "${vhost_file}"; then
        server_name=$(awk '/ServerName/ {print $2}' $vhost_file)
        ssl_enabled=$(awk '/SSLEngine/ {print $2}' $vhost_file)
        bind_port=$(grep -h "<VirtualHost .*>" $vhost_file | sed 's/<VirtualHost .*:\(.*\)>/\1/')
        wsgi_alias=$(awk '/WSGIScriptAlias/ {print $2}' $vhost_file)
        proto=http
        if [[ $ssl_enabled == "on" ]]; then
            proto=https
        fi
        if [[ $wsgi_alias != "/" ]]; then
            wsgi_alias="${wsgi_alias}/"
        fi
        echo ${proto}://${server_name}:${bind_port}${wsgi_alias}
    else
        exit 1
    fi
}

check_swift_interval() {
    service=$1
    if pgrep -f swift-${service} >&3 2>&1; then
        interval=$(get_config_val $conf $service interval 300)
        last=$(grep -o '"replication_last": [0-9]*' $cache | cut -f 2 -d " ")
        now=$(date +%s)
        if [ $(expr $now - $last) -gt $interval ]; then
            echo "Last replication run did not finish within interval of $interval seconds."
            exit 1
        fi
    fi
}

# Wrap an IPv6 address in square brackets if not already wrapped
wrap_ipv6() {
    ip=$1

    if [[ $ip =~ ":" ]] && [[ $ip != *\] ]]; then
        echo [$ip]
    else
        echo $ip
    fi
}
