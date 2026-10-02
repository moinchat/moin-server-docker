ARG VERSION=2026.2
ARG SHA256_AMD64=242a47c68c3a350a428790060d9205f6d0ae8cc30c59c564e44123ca18c52ed7
ARG SHA256_ARM64=9e5a27c7c879b4b4fb206909dea163c36877de2ea5ce3519b85af746b4e5d02e
ARG DEBIAN=debian:trixie-slim@sha256:a99cfc517144bc59b1978475ec53b46ecabec7e43635402ee5b77cc54cd1b20a
ARG DOWNLOADS=https://moin.chat/downloads/server

FROM scratch AS download
ARG VERSION SHA256_AMD64 SHA256_ARM64 DOWNLOADS
ADD --checksum=sha256:${SHA256_AMD64} \
    ${DOWNLOADS}/${VERSION}/moin-server-${VERSION}-x86_64-unknown-linux-musl.tar.gz \
    /amd64.tar.gz
ADD --checksum=sha256:${SHA256_ARM64} \
    ${DOWNLOADS}/${VERSION}/moin-server-${VERSION}-aarch64-unknown-linux-musl.tar.gz \
    /arm64.tar.gz

FROM --platform=$BUILDPLATFORM ${DEBIAN} AS rootfs
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*
ARG TARGETARCH
RUN --mount=from=download,target=/download \
    install -d /rootfs/usr/local/bin /rootfs/usr/share/doc/moin-server /rootfs/data \
    && tar -xzf "/download/${TARGETARCH}.tar.gz" -C /tmp --strip-components=1 \
    && install -m 0755 /tmp/moin-server /rootfs/usr/local/bin/ \
    && install -m 0644 /tmp/THIRD-PARTY-NOTICES /rootfs/usr/share/doc/moin-server/ \
    && groupadd --gid 10001 moin \
    && useradd --uid 10001 --gid moin --no-create-home --home-dir /data \
         --shell /usr/sbin/nologin moin

FROM ${DEBIAN}
ARG VERSION
LABEL org.opencontainers.image.title="moin-server" \
      org.opencontainers.image.description="Moin community server" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.source="https://github.com/moinchat/moin-server-docker" \
      org.opencontainers.image.documentation="https://moin.chat/docs/server/"
COPY --from=rootfs /rootfs/usr/ /usr/
COPY --from=rootfs /etc/passwd /etc/group /etc/
COPY --from=rootfs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=rootfs --chown=10001:10001 --chmod=0700 /rootfs/data/ /data/
COPY moin-server.toml /config/moin-server.toml
ENV HOME=/data
WORKDIR /data
USER 10001:10001
VOLUME ["/config", "/data"]
STOPSIGNAL SIGTERM
ENTRYPOINT ["/usr/local/bin/moin-server"]
CMD ["--config", "/config/moin-server.toml"]
