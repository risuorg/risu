FROM registry.centos.org/centos/centos7-atomic:latest
MAINTAINER Pablo Iranzo <piranzo@redhat.com>

LABEL name="citellus/citellus" \
      maintainer="piranzo@redhat.com" \
      vendor="Citellus" \
      version="1.0" \
      release="1" \
      summary="System configuration validation program" \
      description="Citellus is a program that should help with system configuration validation on either live system or any sort of snapshot of the filesystem."

ENV USER_NAME=citellus \
    USER_UID=10001

# shadow-utils is required for useradd command...
RUN microdnf install --nodocs epel-release && \
    microdnf install --nodocs python-pip shadow-utils && \
    useradd -l -u ${USER_UID} -r -g 0 -s /sbin/nologin \
      -c "${USER_NAME} application user" ${USER_NAME} && \
    microdnf remove shadow-utils libsemanage audit-libs libcap-ng ustr && \
    microdnf clean all

RUN pip install citellus --no-cache-dir && \
    mkdir -p /data

USER 10001
VOLUME /data
ENTRYPOINT ["/usr/bin/citellus.py"]
CMD ["-h"]
