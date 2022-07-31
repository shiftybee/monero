FROM ubuntu:20.04 AS builder
# Gave up on trying to build on Alpine.  Most of the code here taken from the Official Monero github or P2Pool.
ARG MONERO_VERSION=latest
WORKDIR /src

RUN set -ex && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt install --no-install-recommends --yes \
        automake \
        autotools-dev \
        bsdmainutils \
        build-essential \
        ca-certificates \
        ccache \
        cmake \
        curl \
        git \
        libtool \
        pkg-config \
        gperf

RUN	git clone --recursive https://github.com/monero-project/monero && \
    cd monero && \
	# If ARG $MONERO_VERSION is latest, then this line will choose the latest version based on the cloned git repo
	if [ "$MONERO_VERSION" = "latest" ]; then MONERO_VERSION=$(git describe --tags $(git rev-list --tags --max-count=1)); fi && \
    git checkout $MONERO_VERSION && \
    git submodule sync && git submodule update --init --force --recursive && \
	rm -rf build && \
    make depends -j$(nproc) target=x86_64-linux-gnu


FROM alpine:latest

RUN apk add --no-cache ca-certificates && \
    addgroup -g 1000 monero && \
    adduser --uid 1000 --disabled-password --ingroup monero --shell /sbin/nologin --home /home/monero monero && \
	mkdir -p /wallet /home/monero/.bitmonero && \
	chown -R monero:monero /home/monero/.bitmonero && \
	chown -R monero:monero /wallet
COPY --from=builder /src/monero/build/x86_64-linux-gnu/release/bin /usr/local/bin/
USER monero

EXPOSE 18080 18081 18083

VOLUME /home/monero/.bitmonero
VOLUME /wallet

WORKDIR /home/monero



ENTRYPOINT ["monerod"]
CMD ["--zmq-pub tcp://0.0.0.0:18083 \
      --enforce-dns-checkpointing \ 
      --enable-dns-blocklist \
      --non-interactive \
      --p2p-bind-ip=0.0.0.0 \
      --p2p-bind-port=18080 \
      --rpc-bind-ip=0.0.0.0 \
      --rpc-bind-port=18081 \
      --restricted-rpc \
      --confirm-external-bind \
      --log-level=0 \
      --fast-block-sync=0"]
