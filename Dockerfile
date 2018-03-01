FROM registry.centos.org/centos/centos7-atomic:latest
MAINTAINER Pablo Iranzo <piranzo@redhat.com>

LABEL name="citellus/citellus" \
      maintainer="piranzo@redhat.com" \
      vendor="Citellus" \
      version="1.0" \
      release="1" \
      summary="System configuration validation program" \
      description="Citellus is a program that should help with system configuration validation on either live system or any sort of snapshot of the filesystem."

ENV APP_ROOT=/citellus

ENV USER_NAME=default \
    USER_UID=10001

RUN INSTALL_PKGS="python \
      git" && \
      microdnf install --nodocs ${INSTALL_PKGS} && \
      useradd -l -u ${USER_UID} -r -g 0 -d ${APP_ROOT} -s /sbin/nologin \
      -c "${USER_NAME} application user" ${USER_NAME} && \
      microdnf clean all

RUN git clone https://github.com/zerodayz/citellus.git ${APP_ROOT} && \
    mkdir -p ${APP_ROOT}/data && \
    chmod -R u+x ${APP_ROOT} && \
    chown -R ${USER_UID}:0 ${APP_ROOT} && \
    chmod -R g=u ${APP_ROOT}

USER 10001
WORKDIR ${APP_ROOT}
VOLUME ${APP_ROOT}/data
ENTRYPOINT ["/citellus/citellus.py"]
CMD ["-h"]
