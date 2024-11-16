ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG user=doris
ARG group=doris
ARG uid=1000
ARG gid=1000
ARG GOSU_VERSION
ARG S6_OVERLAY_VERSION
ARG RG_VERSION
ARG YQ_VERSION
ARG WAIT4X_VERSION
ARG DORIS_VERSION
ARG CURL_OPTS

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.utf8 \
    GOSU_VERSION=${GOSU_VERSION:-1.17} \
    S6_OVERLAY_VERSION=${S6_OVERLAY_VERSION:-3.2.0.2} \
    RG_VERSION=${RG_VERSION:-14.1.1} \
    YQ_VERSION=${YQ_VERSION:-v4.44.3} \
    WAIT4X_VERSION=${WAIT4X_VERSION:-v2.14.1} \
    DORIS_VERSION=${DORIS_VERSION:-1.2.5} \
    FE_ARROW_FLIGHT_SQL_PORT=${FE_ARROW_FLIGHT_SQL_PORT:-10030} \
    BE_ARROW_FLIGHT_SQL_PORT=${BE_ARROW_FLIGHT_SQL_PORT:-10040} \
    ENABLE_FQDN_MODE=${ENABLE_FQDN_MODE:-true}
    



RUN set -ex; \
    apt-get clean && \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get install -yq --no-install-recommends \
    locales \
    ca-certificates \
    openssh-client \
    psmisc \
    procps \
    tree \
    libfreetype6-dev \
    fontconfig \
    unzip \
    xz-utils \
    p7zip-full \
    zip \
    gosu \
    file \
    zstd \
    bzip2 \
    netcat-openbsd \
    patchelf gdb binutils binutils-common mysql-client \
    curl wget less vim htop iproute2 numactl jq iotop sysstat \
    tcpdump iputils-ping dnsutils strace lsof blktrace tzdata \
    bpfcc-tools silversearcher-ag \
    net-tools && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 && \
    ( if id ubuntu 2>/dev/null; then  userdel -r ubuntu; fi ) && \
    groupadd -g ${gid} ${group} && useradd -u ${uid} -g ${gid} -m -s /bin/bash ${user} && \
    mkdir -p /opt/apache-doris; \
    chown -R ${uid}:${gid} /opt/apache-doris; \
    rm -rf /var/lib/apt/lists/*;



RUN set -ex; \
    ARCH="$(uname -m)"; \
    case "${ARCH}" in \
        aarch64|arm64) \
            yqArch="arm64"; \
            s6overlayArch="aarch64"; \
            wait4xArch="arm64"; \
            ripgrepArch="aarch64-unknown-linux-gnu"; \
            if echo "${DORIS_VERSION}" | grep -q '^1'; then dorisArch="aarch64"; dorisFileExt=".tar.xz"; tarCmd="J"; else dorisArch="arm64"; dorisFileExt=".tar.gz"; tarCmd="z"; fi; \
            ;; \
        amd64|x86_64) \
            yqArch="amd64"; \
            s6overlayArch="x86_64"; \
            wait4xArch="amd64"; \
            ripgrepArch="x86_64-unknown-linux-musl"; \
            if echo "${DORIS_VERSION}" | grep -q '^1'; then dorisArch="x86_64"; dorisFileExt=".tar.xz"; tarCmd="J"; else dorisArch="x64"; dorisFileExt=".tar.gz"; tarCmd="z"; fi; \
            ;; \
        *) \
            echo "Unsupported arch: ${ARCH}"; \
            exit 1; \
            ;; \
    esac; \
    curl ${CURL_OPTS} --retry 3 -f#SL https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${s6overlayArch}.tar.xz | tar -Jxpv -C /; \
    curl ${CURL_OPTS} --retry 3 -f#SL https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz | tar -Jxpv -C /; \
    curl ${CURL_OPTS} --retry 3 -f#SL https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz | tar -Jxpv -C /; \
    curl ${CURL_OPTS} --retry 3 -f#SL https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep-${RG_VERSION}-${ripgrepArch}.tar.gz | tar -xzv --strip-components=1 -C /usr/local/bin/ ripgrep-${RG_VERSION}-${ripgrepArch}/rg;  \
    curl ${CURL_OPTS} --retry 3 -f#SL https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${yqArch} -o /usr/local/bin/yq; \
    curl ${CURL_OPTS} --retry 3 -f#SL https://github.com/atkrad/wait4x/releases/download/${WAIT4X_VERSION}/wait4x-linux-${wait4xArch}.tar.gz | tar -xvz -C /usr/local/bin wait4x; \
    curl              --retry 3 -f#SL https://apache-doris-releases.oss-accelerate.aliyuncs.com/apache-doris-${DORIS_VERSION}-bin-${dorisArch}${dorisFileExt} | tar -xv${tarCmd} -C /opt/apache-doris --strip-components=1; \
    chown -R ${uid}:${gid} /opt/apache-doris; \
    chmod +x /usr/local/bin/yq; \
    chmod +x /usr/local/bin/rg; \
    chmod +x /usr/local/bin/wait4x; \
    sed -i.bak -e '/export DORIS_LOG_TO_STDERR=1/{n;s/MIT}}/MIT}} exec/;}' /opt/apache-doris/fe/bin/start_fe.sh; \
    sed -i.bak -e '/export DORIS_LOG_TO_STDERR=1/{n;s/MIT}}/MIT}} exec/;}' /opt/apache-doris/be/bin/start_be.sh; \
    chown -R ${uid}:${gid} /opt/apache-doris;


COPY rootfs /

WORKDIR /opt/apache-doris


EXPOSE 8030
EXPOSE 9020
EXPOSE 9030
EXPOSE 9010
EXPOSE 10030
EXPOSE 9060
EXPOSE 8040
EXPOSE 9050
EXPOSE 8060
EXPOSE 10040
EXPOSE 5000
EXPOSE 5100



STOPSIGNAL SIGTERM

ENTRYPOINT ["/docker-entrypoint.sh"]
