# Introduction

Citellus is a program that should help with system configuration validation on either live system or any sort of snapshot of the filesystem.

Please if you have any idea on any improvements please do not hesitate to open an issue.

## Usage help
We are developing framework in python, the bash framework has been deprecated. Python framework is the only supported framework.

```
# ./citellus.py -h
usage: citellus.py [arguments] [-h] [-l] [-v] [-d {info,debug,warn,critical}]
                               [-s]

Citellus allows to analyze a directory against common set of tests, useful for
finding common configuration errors

optional arguments:
  -h, --help            show this help message and exit
  -l, --live            Work on a live system instead of a snapshot
  -v, --verbose         Execute in verbose mode
  -d {info,debug,warn,critical}, --verbosity {info,debug,warn,critical}
                        Set verbosity level for messages while running/logging
  -s, --silent          Enable silent mode, only errors on tests written

```

## Doing a live check example

This is an example of execution of Citellus using all openstack and pacemaker tests collections.
```
# ./citellus.py -v -l plugins/openstack/ plugins/pacemaker/
_________ .__  __         .__  .__                
\_   ___ \|__|/  |_  ____ |  | |  |  __ __  ______
/    \  \/|  \   __\/ __ \|  | |  | |  |  \/  ___/
\     \___|  ||  | \  ___/|  |_|  |_|  |  /\___ \ 
 \______  /__||__|  \___  >____/____/____//____  >
        \/              \/                     \/ 
found #19 tests at plugins/openstack/, plugins/pacemaker/
mode: live
# plugins/openstack/debug.sh: failed
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
    
# plugins/openstack/traceback.sh: failed
    /var/log/aodh/aodh-dbsync.log (1 times)
    /var/log/ceilometer/agent-notification.log (1 times)
    /var/log/ceilometer/alarm-evaluator.log (1 times)
    /var/log/nova/nova-cert.log (56 times)
    /var/log/nova/nova-conductor.log (1 times)
    
# plugins/openstack/network/sriov.sh: skipped
    works only against fs snapshot now
    
# plugins/openstack/rabbitmq/file_descriptors.sh: skipped
    works only against controller node
    
# plugins/openstack/rabbitmq/rpc_issues.sh: failed
    /var/log/aodh/listener.log (4 times)
    /var/log/aodh/notifier.log (4 times)
    /var/log/ceilometer/agent-notification.log (5 times)
    /var/log/ceilometer/alarm-notifier.log (8 times)
    /var/log/ceilometer/collector.log (22 times)
    /var/log/nova/nova-cert.log (25 times)
    
# plugins/pacemaker/failed_actions.sh: skipped
    pacemaker is not running on this node
    
# plugins/pacemaker/fence_device.sh: skipped
    pacemaker is not running on this node
    
# plugins/pacemaker/nodes_number.sh: skipped
    pacemaker is not running on this node
    
# plugins/pacemaker/stonith_enabled.sh: skipped
    pacemaker is not running on this node
    
# plugins/pacemaker/stopped_resources.sh: skipped
    pacemaker is not running on this node
    
# ['/openstack/version.sh', '/openstack/crontab/heat_stack-purge.sh', '/openstack/crontab/keystone_cleanup.sh', '/openstack/hardware/memory.sh', '/openstack/iptables/metadata_redirect.sh', '/openstack/keystone/cleanup_last-run.sh', '/openstack/keystone/cleanup_runs.sh', '/openstack/mysql/keystone_tokendb.sh', '/openstack/systemd/services.sh']: okay
```

And exactly the same execution against the fs snapshot, with one difference, omitting the ```-l``` and instead specifying the directory with fs snapshot.

## Doing a fs snapshot check example

This is an example of execution of Citellus using ```plugins/pacemaker``` and ```plugins/openstack``` collections against fs snapshot ```sosreport-controller-1.localdomain-20170705201135```
```
# ./citellus.py -v /root/sosreport-controller-1.localdomain-20170705201135/ plugins/openstack/ plugins/pacemaker/
_________ .__  __         .__  .__                
\_   ___ \|__|/  |_  ____ |  | |  |  __ __  ______
/    \  \/|  \   __\/ __ \|  | |  | |  |  \/  ___/
\     \___|  ||  | \  ___/|  |_|  |_|  |  /\___ \ 
 \______  /__||__|  \___  >____/____/____//____  >
        \/              \/                     \/ 
found #19 tests at plugins/openstack/, plugins/pacemaker/
mode: fs snapshot /root/sosreport-controller-1.localdomain-20170705201135/
# plugins/openstack/debug.sh: failed
    disabled in /etc/ceilometer/ceilometer.conf
    disabled in /etc/cinder/cinder.conf
    disabled in /etc/cinder/rootwrap.conf
    disabled in /etc/glance/glance-api.conf
    disabled in /etc/glance/glance-cache.conf
    disabled in /etc/glance/glance-glare.conf
    disabled in /etc/glance/glance-registry.conf
    disabled in /etc/glance/glance-scrubber.conf
    disabled in /etc/glance/glance-swift.conf
    disabled in /etc/heat/heat.conf
    disabled in /etc/keystone/keystone.conf
    disabled in /etc/keystone/logging.conf
    disabled in /etc/neutron/dnsmasq-neutron.conf
    disabled in /etc/neutron/neutron.conf
    disabled in /etc/neutron/neutron_lbaas.conf
    disabled in /etc/neutron/rootwrap.conf
    disabled in /etc/neutron/services_lbaas.conf
    disabled in /etc/nova/nova.conf
    disabled in /etc/nova/rootwrap.conf
    disabled in /etc/puppet/auth.conf
    disabled in /etc/puppet/puppet.conf
    disabled in /etc/sahara/rootwrap.conf
    disabled in /etc/sahara/sahara.conf
    disabled in /etc/selinux/semanage.conf
    disabled in /etc/swift/account-server.conf
    disabled in /etc/swift/container-reconciler.conf
    disabled in /etc/swift/container-server.conf
    disabled in /etc/swift/object-expirer.conf
    disabled in /etc/swift/object-server.conf
    disabled in /etc/swift/proxy-server.conf
    disabled in /etc/swift/swift.conf
    
# plugins/openstack/traceback.sh: failed
    /var/log/ceilometer/alarm-evaluator.log (1907 times)
    /var/log/ceilometer/central.log (137 times)
    /var/log/cinder/scheduler.log (1 times)
    /var/log/heat/heat-engine.log (20 times)
    /var/log/nova/nova-api.log (3 times)
    /var/log/nova/nova-conductor.log (18 times)
    /var/log/nova/nova-consoleauth.log (5 times)
    /var/log/nova/nova-scheduler.log (1 times)
    /var/log/swift/swift.log (3 times)
    
# plugins/openstack/hardware/memory.sh: failed
    memory is lower than 16gb ram
    
# plugins/openstack/iptables/metadata_redirect.sh: skipped
    works on director node only
    
# plugins/openstack/mysql/keystone_tokendb.sh: skipped
    works on live-system only
    
# plugins/openstack/network/sriov.sh: failed
    virtual function is disabled
    vfio_iommu module is not loaded
    missing allow_unsafe_interrupts file - skipped
    missing intel_iommu=on on cmdline
    missing iommu=pt on cmdline
    
# plugins/openstack/rabbitmq/rpc_issues.sh: failed
    /var/log/ceilometer/agent-notification.log (2 times)
    /var/log/cinder/scheduler.log (6 times)
    /var/log/heat/heat-engine.log (14 times)
    /var/log/neutron/dhcp-agent.log (12 times)
    /var/log/neutron/l3-agent.log (4 times)
    /var/log/nova/nova-conductor.log (14 times)
    /var/log/nova/nova-consoleauth.log (4 times)
    
# plugins/pacemaker/fence_device.sh: skipped
    works on live-system only
    
# plugins/pacemaker/stonith_enabled.sh: failed
# plugins/pacemaker/stopped_resources.sh: failed
# ['/openstack/version.sh', '/openstack/crontab/heat_stack-purge.sh', '/openstack/crontab/keystone_cleanup.sh', '/openstack/keystone/cleanup_last-run.sh', '/openstack/keystone/cleanup_runs.sh', '/openstack/rabbitmq/file_descriptors.sh', '/openstack/systemd/services.sh', '/pacemaker/failed_actions.sh', '/pacemaker/nodes_number.sh']: okay 
```
