ARG ARCH="amd64"
ARG OS="linux"

FROM alpine
ARG ARCH="amd64"
ARG OS="linux"
COPY .build/${OS}-${ARCH}/blackbox_exporter  /bin/blackbox_exporter
RUN apk add libcap && setcap cap_net_raw+ep /bin/blackbox_exporter
COPY blackbox.yml  /etc/blackbox_exporter/config.yml

EXPOSE      9115
ENTRYPOINT  [ "/bin/blackbox_exporter" ]
CMD         [ "--config.file=/etc/blackbox_exporter/config.yml" ]
