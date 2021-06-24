# Based on https://github.com/RHsyseng/container-rhel-examples/blob/master/starter-rhel-atomic/Dockerfile
FROM registry.centos.org/centos/centos7-atomic:latest
MAINTAINER Risu developers <risuorg _AT_ googlegroups.com>

LABEL name="risu/risu" \
  maintainer="risuorg _AT_ googlegroups.com" \
  vendor="Risu" \
  version="1.0.0" \
  release="1" \
  summary="System configuration validation program" \
  description="Risu is a program that should help with system configuration validation on either live system or any sort of snapshot of the filesystem."

ENV USER_NAME=risu \
  USER_UID=10001 \
  LC_ALL=en_US.utf8

# Required for useradd command and pip
RUN PRERREQ_PKGS="shadow-utils \
  libsemanage \
  ustr \
  audit-libs \
  libcap-ng \
  epel-release" && \
  REQ_PKGS="bc \
  python3-pip" && \
  microdnf install --nodocs ${PRERREQ_PKGS} && \
  microdnf install --nodocs ${REQ_PKGS} && \
  useradd -l -u ${USER_UID} -r -g 0 -s /sbin/nologin \
  -c "${USER_NAME} application user" ${USER_NAME} && \
  microdnf remove ${PRERREQ_PKGS} && \
  microdnf clean all

RUN pip3 install --upgrade pip --no-cache-dir && \
  pip3 install --upgrade pbr --no-cache-dir && \
  pip3 install --upgrade risu --no-cache-dir && \
  mkdir -p /data && \
  chmod -R u+x /data && \
  chown -R ${USER_UID}:0 /data && \
  chmod -R g=u /data

USER 10001
VOLUME /data
ENTRYPOINT ["/usr/local/bin/risu.py"]
CMD ["-h"]
