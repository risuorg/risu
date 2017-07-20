# Introduction

Citellus is a program that should help faster identify common pitfails of OpenStack deployments from live system or any sort of snapshot of the filesystem.

Please if you have any idea on any improvements please do not hesitate to open an issue.

## Doing a live check example

```
[root@undercloud-0 citellus]# ./citellus --live
_________ .__  __         .__  .__                
\_   ___ \|__|/  |_  ____ |  | |  |  __ __  ______
/    \  \/|  \   __\/ __ \|  | |  | |  |  \/  ___/
\     \___|  ||  | \  ___/|  |_|  |_|  |  /\___ \ 
 \______  /__||__|  \___  >____/____/____//____  >
        \/              \/                     \/ 
citellus: found 4 tests
mode: live
# ./plugins/openstack/crontab_keystone_cleanup.sh: okay 
# ./plugins/openstack/debug.sh: okay 
    disabled in /etc/neutron/neutron.conf
    disabled in /etc/neutron/rootwrap.conf
    disabled in /etc/nova/nova.conf
    disabled in /etc/nova/rootwrap.conf
    disabled in /etc/aodh/aodh.conf
    disabled in /etc/ironic-inspector/dnsmasq.conf
    disabled in /etc/ironic-inspector/inspector-dist.conf
    disabled in /etc/ironic-inspector/inspector.conf
    disabled in /etc/ironic-inspector/rootwrap.conf
    disabled in /etc/sahara/rootwrap.conf
    disabled in /etc/sahara/sahara.conf
    disabled in /etc/zaqar/logging.conf
    disabled in /etc/zaqar/zaqar.conf
    disabled in /etc/swift/container-server.conf
    disabled in /etc/swift/object-server.conf
    disabled in /etc/cinder/cinder.conf
    disabled in /etc/cinder/rootwrap.conf
    disabled in /etc/ceilometer/ceilometer.conf
    disabled in /etc/ironic/ironic.conf
    disabled in /etc/ironic/rootwrap.conf
    disabled in /etc/swift/account-server.conf
    disabled in /etc/glance/glance-api.conf
    disabled in /etc/glance/glance-cache.conf
    disabled in /etc/glance/glance-glare.conf
    disabled in /etc/glance/glance-registry.conf
    disabled in /etc/glance/glance-scrubber.conf
    disabled in /etc/rsyslog.d/openstack-swift.conf
    disabled in /etc/swift/swift.conf
    disabled in /etc/swift/container-reconciler.conf
    disabled in /etc/swift/object-expirer.conf
    disabled in /etc/swift/proxy-server.conf
    disabled in /etc/keystone/keystone.conf
    disabled in /etc/keystone/logging.conf
    disabled in /etc/heat/heat.conf
# ./plugins/openstack/version.sh: okay 
    mitaka
# ./plugins/system/kernel_panic.sh: okay

```

## Doing a fs snapshot check example

```
[root@undercloud-0 citellus]# ./citellus --file /root/sosreport-compute-0.localdomain-20170717184033/
_________ .__  __         .__  .__                
\_   ___ \|__|/  |_  ____ |  | |  |  __ __  ______
/    \  \/|  \   __\/ __ \|  | |  | |  |  \/  ___/
\     \___|  ||  | \  ___/|  |_|  |_|  |  /\___ \ 
 \______  /__||__|  \___  >____/____/____//____  >
        \/              \/                     \/ 
citellus: found 4 tests
mode: fs snapshot /root/sosreport-compute-0.localdomain-20170717184033/
# ./plugins/openstack/crontab_keystone_cleanup.sh: skipped 
    file /var/spool/cron/keystone not found.
# ./plugins/openstack/debug.sh: okay 
    disabled in /etc/ceilometer/ceilometer.conf
    enabled in /etc/cinder/cinder.conf
    disabled in /etc/cinder/rootwrap.conf
    disabled in /etc/glance/glance-api.conf
    disabled in /etc/glance/glance-cache.conf
    disabled in /etc/glance/glance-glare.conf
    disabled in /etc/glance/glance-registry.conf
    disabled in /etc/glance/glance-scrubber.conf
    disabled in /etc/heat/heat.conf
    disabled in /etc/keystone/keystone.conf
    disabled in /etc/keystone/logging.conf
    disabled in /etc/neutron/neutron.conf
    disabled in /etc/neutron/neutron_lbaas.conf
    disabled in /etc/neutron/rootwrap.conf
    disabled in /etc/neutron/services_lbaas.conf
    disabled in /etc/nova/nova.conf
    disabled in /etc/nova/rootwrap.conf
    disabled in /etc/puppet/auth.conf
    disabled in /etc/puppet/puppet.conf
    disabled in /etc/selinux/semanage.conf
    disabled in /etc/swift/account-server.conf
    disabled in /etc/swift/container-reconciler.conf
    disabled in /etc/swift/container-server.conf
    disabled in /etc/swift/object-expirer.conf
    disabled in /etc/swift/object-server.conf
    disabled in /etc/swift/proxy-server.conf
    disabled in /etc/swift/swift.conf
# ./plugins/openstack/version.sh: okay 
    mitaka
# ./plugins/system/kernel_panic.sh: skipped 
    file /sos_commands/logs/journalctl_--no-pager_--boot not found.
```

## Writing checks

Citellus tests should conform to the following standards:

- The test script must be executable. Citellus will ignore tests for
  which it does not have execute permission.

- The test should return one of the following error codes to indicate
  the test result:

    - 0 -- success
    - 1 -- failure
    - 2 -- skipped

A test may make use of the following standard environment variables:

- `$CITELLUS_ROOT` -- tests that parse files should locate them
  relative to this directory.  For example, if your script needs to
  examine `/etc/sysctl.conf`, it might have something like:

          if grep -q '^net.ipv4.ip_forward = 1' "${CITELLUS_ROOT}/etc/sysctl.conf"; then
              ...
          fi
- `$CITELLUS_LIVE` -- if `0`, tests are running against a filesystem
  snapshot of some sort.  Tests should not attempt to use commands
  that interrogate the system on which it is running.  If this
  variable is `1`, the tests are running on a live system.
