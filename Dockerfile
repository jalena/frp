# syntax=docker/dockerfile:1

ARG ALPINE_VERSION=3.24

FROM alpine:${ALPINE_VERSION} AS downloader
ARG FRP_VERSION
ARG TARGETOS
ARG TARGETARCH

WORKDIR /tmp

RUN test -n "${FRP_VERSION}" || (echo "FRP_VERSION build-arg is required" && exit 1) && \
    apk add --no-cache curl tar && \
    VER_NUM="${FRP_VERSION#v}" && \
    ARCHIVE="frp_${VER_NUM}_${TARGETOS}_${TARGETARCH}.tar.gz" && \
    BASE_URL="https://github.com/fatedier/frp/releases/download/${FRP_VERSION}" && \
    curl -fsSL -o "${ARCHIVE}" "${BASE_URL}/${ARCHIVE}" && \
    curl -fsSL -o "frp_sha256_checksums.txt" "${BASE_URL}/frp_sha256_checksums.txt" && \
    grep " ${ARCHIVE}\$" frp_sha256_checksums.txt | sha256sum -c - && \
    tar -zxf "${ARCHIVE}" && \
    mkdir -p /out && \
    mv "frp_${VER_NUM}_${TARGETOS}_${TARGETARCH}/frpc" /out/frpc && \
    mv "frp_${VER_NUM}_${TARGETOS}_${TARGETARCH}/frps" /out/frps && \
    mv "frp_${VER_NUM}_${TARGETOS}_${TARGETARCH}/frpc.toml" /out/frpc.toml && \
    mv "frp_${VER_NUM}_${TARGETOS}_${TARGETARCH}/frps.toml" /out/frps.toml && \
    chmod +x /out/frpc /out/frps

FROM alpine:${ALPINE_VERSION} AS base
LABEL maintainer="jalena@bcsytv.com"
ENV TZ=Asia/Shanghai
RUN apk add --no-cache tzdata ca-certificates
WORKDIR /etc/frp

FROM base AS frpc
COPY --from=downloader /out/frpc /usr/bin/frpc
COPY --from=downloader /out/frpc.toml /etc/frp/frpc.toml
ENTRYPOINT ["/usr/bin/frpc"]
CMD ["-c", "/etc/frp/frpc.toml"]

FROM base AS frps
COPY --from=downloader /out/frps /usr/bin/frps
COPY --from=downloader /out/frps.toml /etc/frp/frps.toml
ENTRYPOINT ["/usr/bin/frps"]
CMD ["-c", "/etc/frp/frps.toml"]
