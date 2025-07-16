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

# long_name: SSL certificate validation
# description: Validates SSL certificates for expiration and security issues
# priority: 810

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Check if openssl is available
is_required_command openssl

flag=0

# Look for SSL certificates
if [[ "x$RISU_LIVE" == "x1" ]]; then
    cert_files=$(find /etc/ssl/certs /etc/pki/tls/certs /etc/nginx/ssl /etc/apache2/ssl /etc/httpd/ssl /opt/ssl -name "*.crt" -o -name "*.pem" -o -name "*.cert" 2>/dev/null | head -20)
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    cert_files=$(find "${RISU_ROOT}/etc/ssl/certs" "${RISU_ROOT}/etc/pki/tls/certs" "${RISU_ROOT}/etc/nginx/ssl" "${RISU_ROOT}/etc/apache2/ssl" "${RISU_ROOT}/etc/httpd/ssl" "${RISU_ROOT}/opt/ssl" -name "*.crt" -o -name "*.pem" -o -name "*.cert" 2>/dev/null | head -20)
fi

if [[ -z $cert_files ]]; then
    echo "No SSL certificates found" >&2
    exit ${RC_SKIPPED}
fi

# Function to check certificate expiration
check_cert_expiration() {
    local cert_file="$1"
    local current_date=$(date +%s)

    # Get certificate expiration date
    local exp_date=$(openssl x509 -in "$cert_file" -noout -enddate 2>/dev/null | cut -d'=' -f2)
    if [[ -z $exp_date ]]; then
        echo "Unable to read certificate expiration date: $cert_file" >&2
        return 1
    fi

    local exp_epoch=$(date -d "$exp_date" +%s 2>/dev/null)
    if [[ -z $exp_epoch ]]; then
        echo "Unable to parse certificate expiration date: $cert_file" >&2
        return 1
    fi

    local days_until_expiry=$(((exp_epoch - current_date) / 86400))

    if [[ $days_until_expiry -lt 0 ]]; then
        echo "Certificate expired $((days_until_expiry * -1)) days ago: $cert_file" >&2
        return 1
    elif [[ $days_until_expiry -lt 30 ]]; then
        echo "Certificate expires in $days_until_expiry days: $cert_file" >&2
        return 1
    elif [[ $days_until_expiry -lt 90 ]]; then
        echo "Certificate expires in $days_until_expiry days (warning): $cert_file" >&2
        return 0
    else
        echo "Certificate expires in $days_until_expiry days: $cert_file" >&2
        return 0
    fi
}

# Function to check certificate security
check_cert_security() {
    local cert_file="$1"
    local cert_flag=0

    # Check key size
    local key_size=$(openssl x509 -in "$cert_file" -noout -text 2>/dev/null | grep "Public-Key:" | sed 's/.*(\([0-9]*\) bit).*/\1/')
    if [[ -n $key_size ]]; then
        if [[ $key_size -lt 2048 ]]; then
            echo "Certificate has weak key size ($key_size bits): $cert_file" >&2
            cert_flag=1
        fi
    fi

    # Check signature algorithm
    local sig_alg=$(openssl x509 -in "$cert_file" -noout -text 2>/dev/null | grep "Signature Algorithm:" | head -1 | awk '{print $3}')
    if [[ $sig_alg == "sha1WithRSAEncryption" || $sig_alg == "md5WithRSAEncryption" ]]; then
        echo "Certificate uses weak signature algorithm ($sig_alg): $cert_file" >&2
        cert_flag=1
    fi

    # Check if certificate is self-signed
    local issuer=$(openssl x509 -in "$cert_file" -noout -issuer 2>/dev/null)
    local subject=$(openssl x509 -in "$cert_file" -noout -subject 2>/dev/null)
    if [[ $issuer == "$subject" ]]; then
        echo "Certificate is self-signed: $cert_file" >&2
    fi

    # Check SAN (Subject Alternative Names)
    local san=$(openssl x509 -in "$cert_file" -noout -text 2>/dev/null | grep -A 1 "Subject Alternative Name")
    if [[ -n $san ]]; then
        echo "Certificate has Subject Alternative Names: $cert_file" >&2
    fi

    # Check certificate version
    local version=$(openssl x509 -in "$cert_file" -noout -text 2>/dev/null | grep "Version:" | awk '{print $2}')
    if [[ $version != "3" ]]; then
        echo "Certificate is not version 3: $cert_file" >&2
        cert_flag=1
    fi

    return $cert_flag
}

echo "Checking SSL certificates" >&2

for cert_file in $cert_files; do
    if [[ ! -f $cert_file ]]; then
        continue
    fi

    # Skip if file is too large (likely not a certificate)
    if [[ $(stat -c%s "$cert_file" 2>/dev/null) -gt 100000 ]]; then
        continue
    fi

    echo "Checking certificate: $cert_file" >&2

    # Verify certificate format
    if ! openssl x509 -in "$cert_file" -noout -text >/dev/null 2>&1; then
        echo "Invalid certificate format: $cert_file" >&2
        flag=1
        continue
    fi

    # Check expiration
    if ! check_cert_expiration "$cert_file"; then
        flag=1
    fi

    # Check security
    if ! check_cert_security "$cert_file"; then
        flag=1
    fi

    # Get certificate subject
    subject=$(openssl x509 -in "$cert_file" -noout -subject 2>/dev/null | sed 's/subject=//')
    echo "Certificate subject: $subject" >&2

    # Get certificate issuer
    issuer=$(openssl x509 -in "$cert_file" -noout -issuer 2>/dev/null | sed 's/issuer=//')
    echo "Certificate issuer: $issuer" >&2
done

# Check for private keys in wrong locations
if [[ "x$RISU_LIVE" == "x1" ]]; then
    key_files=$(find /etc/ssl/private /etc/pki/tls/private /etc/nginx/ssl /etc/apache2/ssl /etc/httpd/ssl /opt/ssl -name "*.key" -o -name "*.pem" 2>/dev/null | head -10)
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    key_files=$(find "${RISU_ROOT}/etc/ssl/private" "${RISU_ROOT}/etc/pki/tls/private" "${RISU_ROOT}/etc/nginx/ssl" "${RISU_ROOT}/etc/apache2/ssl" "${RISU_ROOT}/etc/httpd/ssl" "${RISU_ROOT}/opt/ssl" -name "*.key" -o -name "*.pem" 2>/dev/null | head -10)
fi

echo "Checking private key security" >&2

for key_file in $key_files; do
    if [[ ! -f $key_file ]]; then
        continue
    fi

    # Skip if file is too large
    if [[ $(stat -c%s "$key_file" 2>/dev/null) -gt 100000 ]]; then
        continue
    fi

    # Check if it's actually a private key
    if ! openssl rsa -in "$key_file" -noout -check >/dev/null 2>&1 && ! openssl ec -in "$key_file" -noout -check >/dev/null 2>&1; then
        continue
    fi

    echo "Checking private key: $key_file" >&2

    # Check file permissions (only on live systems)
    if [[ "x$RISU_LIVE" == "x1" ]]; then
        perms=$(stat -c "%a" "$key_file")
        if [[ $perms != "600" && $perms != "640" ]]; then
            echo "Private key has insecure permissions ($perms): $key_file" >&2
            flag=1
        fi

        # Check ownership
        owner=$(stat -c "%U" "$key_file")
        if [[ $owner == "root" ]]; then
            echo "Private key owned by root: $key_file" >&2
        else
            echo "Private key owned by $owner: $key_file" >&2
        fi
    fi

    # Check key size
    key_size=$(openssl rsa -in "$key_file" -noout -text 2>/dev/null | grep "Private-Key:" | sed 's/.*(\([0-9]*\) bit).*/\1/')
    if [[ -z $key_size ]]; then
        # Try EC key
        key_size=$(openssl ec -in "$key_file" -noout -text 2>/dev/null | grep "Private-Key:" | sed 's/.*(\([0-9]*\) bit).*/\1/')
    fi

    if [[ -n $key_size ]]; then
        if [[ $key_size -lt 2048 ]]; then
            echo "Private key has weak key size ($key_size bits): $key_file" >&2
            flag=1
        fi
    fi
done

# Check for certificate chain issues
echo "Checking certificate chain validation" >&2

# Common CA bundle locations
if [[ "x$RISU_LIVE" == "x1" ]]; then
    ca_bundle_files=(
        "/etc/ssl/certs/ca-certificates.crt"
        "/etc/pki/tls/certs/ca-bundle.crt"
        "/etc/ssl/ca-bundle.pem"
    )
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    ca_bundle_files=(
        "${RISU_ROOT}/etc/ssl/certs/ca-certificates.crt"
        "${RISU_ROOT}/etc/pki/tls/certs/ca-bundle.crt"
        "${RISU_ROOT}/etc/ssl/ca-bundle.pem"
    )
fi

ca_bundle=""
for bundle in "${ca_bundle_files[@]}"; do
    if [[ -f $bundle ]]; then
        ca_bundle="$bundle"
        break
    fi
done

if [[ -n $ca_bundle ]]; then
    echo "CA bundle found: $ca_bundle" >&2

    # Check CA bundle age
    if [[ "x$RISU_LIVE" == "x1" ]]; then
        bundle_age=$(find "$ca_bundle" -mtime +90 2>/dev/null)
        if [[ -n $bundle_age ]]; then
            echo "CA bundle is older than 90 days: $ca_bundle" >&2
        fi
    fi
else
    echo "No CA bundle found" >&2
fi

if [[ $flag == "1" ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
