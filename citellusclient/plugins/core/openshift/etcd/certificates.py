#!/usr/bin/env python
# coding=utf-8

# Copyright (C) 2018  Juan Luis de Sousa-Valadas (jdesousa@redhat.com)

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

# long_name: Validate etcd certificates
# description: Verify etcd certificates are valid for this host
# priority: 1000


from __future__ import print_function

import os
import re
import socket
import string
import subprocess
import sys

try:
    import OpenSSL.crypto
except ImportError:
    print("This test requires pyopenssl", file=sys.stderr)
    sys.exit(int(os.environ['RC_SKIPPED']))


def get_etcd_addr_from_netstat(nsout):
    """
    Gets etcd address from listening port on netstat
    :param nsout: netstat output
    :return: local ip address we listen on
    """
    nsout = re.sub('[ \t]+', ' ', nsout)
    for l in nsout.splitlines():
        if "tcp" in l and "etcd" in l and "LISTEN" in l and "2379" in l:
            # Column 3 = Local Address
            return l.split(" ")[3].split(":")[0]

    errorprint("Citellus expects etcd to be running and listening on tcp/2379")


def get_names(cert_file):
    """
    Get CN or subjectAlt from certificate
    :param cert_file: file to open certificate from
    :return: names found
    """
    # Load the X509
    c = None
    try:
        fd = open(cert_file, 'r')
        c = fd.read()
        fd.close()

    except IOError:
        errorprint("Unable to open %s" % cert_file)

    crt = None
    try:
        crt = OpenSSL.crypto.load_certificate(OpenSSL.crypto.FILETYPE_PEM, c)
    except:
        # pyopenssl only producess Error
        errorprint("Unable to parse as PEM X509 certificate %s" % cert_file)

    names = []
    # Get subject
    for component in crt.get_subject().get_components():
        if component[0] == "CN":
            names.append(component[1])

    # Get subject alt names
    san = None
    for i in range(crt.get_extension_count()):
        ext = crt.get_extension(i)
        if ext.get_short_name() == 'subjectAltName':
            san = str(ext)
    if san is not None:
        for name in san.split(", "):
            names.append(name.split(":")[1])

    return names


def crt_matches_key(crt, key):
    """
    Check that certificate matches key
    :param crt: certificate file
    :param key: key file
    :return: bool
    """
    try:
        # We call subprocess.check_output because the pyOpenSSL version
        # shipped in RHEL 7.4 doesn't provide any mechanism to check the
        # private key and certificate match. Fedora ships a way more recent
        # version.
        crt_modulus = subprocess.check_output(["openssl", "x509", "-noout",
                                              "-modulus", "-in", crt])

        key_modulus = subprocess.check_output(["openssl", "rsa", "-noout",
                                              "-modulus", "-in", key])

        return crt_modulus == key_modulus
    except subprocess.CalledProcessError as e:
        errorprint(e.sterror)
        return False


def crt_is_signed_by(crt, ca):
    """
    Check crt signing
    :param crt: certificate
    :param ca: certificate authority
    :return: bool
    """
    try:
        # We call subprocess.check_output because the pyOpenSSL version
        # shipped in RHEL 7.4 doesn't provide any mechanism to check the
        # private key and certificate match. Fedora ships a way more recent
        # version.
        subprocess.check_output(["openssl", "verify", "-CAfile", ca, crt])
        return True
    except:
        return False


def errorprint(*args, **kwargs):
    """
    Prints to stderr a string
    :type args: String to print
    """
    print(*args, file=sys.stderr, **kwargs)


def exitcitellus(code=False, msg=False):
    """
    Exits back to citellus with errorcode and message
    :param msg: Message to report on stderr
    :param code: return code
    """
    if msg:
        errorprint(msg)
    sys.exit(code)


def main():
    """
    Main code
    """

    # Getting environment
    root_path = os.getenv('CITELLUS_ROOT', '') + "/"
    RC_OKAY = int(os.environ['RC_OKAY'])
    RC_FAILED = int(os.environ['RC_FAILED'])
    RC_SKIPPED = int(os.environ['RC_SKIPPED'])
    citellus_live = os.getenv('CITELLUS_LIVE', '0')
    exit_code = RC_OKAY

    error_list = []

    ca_crt = root_path + "/etc/etcd/ca.crt"
    peer_crt = root_path + "/etc/etcd/peer.crt"
    server_crt = root_path + "/etc/etcd/server.crt"

    peer_key = root_path + "/etc/etcd/peer.key"
    server_key = root_path + "/etc/etcd/server.key"

    for filename in [ca_crt, peer_crt, server_crt]:
        if not os.access(filename, os.R_OK):
            exitcitellus(code=RC_SKIPPED,
                         msg='Missing access to required file %s' % filename)

    if citellus_live != "0":
        fqdn = socket.getfqdn()
    else:
        fd = open(root_path + "sos_commands/general/hostname")
        fqdn = fd.read().rstrip()
        fd.close()

    # Should query etcd API but we're waiting on sos being
    # updated on RHEL. Needs commit ae56ea5 or greater
    netstat_out = None
    if citellus_live != "0":
        try:
            netstat_out = subprocess.check_output(["netstat", "-W", "-neopa"])
        except:
            errorprint("Error calling netstat -W -neopa")
    else:
        try:
            fd = open(root_path + "netstat")
            netstat_out = fd.read()
            fd.close()
        except:
            errorprint("Error getting netstat -W -neopa from sosreport")

    ipaddr = get_etcd_addr_from_netstat(netstat_out)

    for crt in [peer_crt, server_crt]:
        alt_names = get_names(crt)
        if fqdn not in alt_names:
            exit_code = RC_FAILED
            error_list.append("%s is not valid for %s" % (crt, fqdn))
        if ipaddr not in alt_names:
            exit_code = RC_FAILED
            error_list.append("%s is not valid for %s" % (crt, ipaddr))

    for p in [(peer_crt, peer_key), (server_crt, server_key)]:
        if not crt_matches_key(p[0], p[1]):
            exit_code = RC_FAILED
            error_list.append("%s does not match %s" % (p[0], p[1]))

    for crt in [peer_crt, server_crt]:
        if not crt_is_signed_by(crt, ca_crt):
            exit_code = RC_FAILED
            error_list.append("%s is not signed by %s" % (crt, ca_crt))

    msg = string.join(error_list, '\n')
    exitcitellus(exit_code, msg=msg)


if __name__ == "__main__":
    main()
