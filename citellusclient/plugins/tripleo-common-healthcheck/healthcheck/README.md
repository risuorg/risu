# Health check commands

The scripts in this directory are meant to implement the
[container-healthcheck][] blueprint.    They are written to be compatible
with the Docker [HEALTHCHECK][] api.

[container-healthcheck]: https://blueprints.launchpad.net/tripleo/+spec/container-healthchecks
[healthcheck]: https://docs.docker.com/engine/reference/builder/#healthcheck

The scripts expect to source
`/usr/share/tripleo-common/healthcheck/common.sh`. If you
want to run scripts without installing to that file, you can set the
`HEALTHCHECKS_DIR` environment variable, e.g:

        $ export HEALTHCHECKS_DIR=$PWD
        $ ./heat-api
        {"versions": [{"status": "CURRENT", "id": "v1.0", "links": [{"href": "http://192.168.24.1:8004/v1/", "rel": "self"}]}]}
        300 192.168.24.1:8004 0.002 seconds
