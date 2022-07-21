from alpine:edge
run apk add --no-cache monero ca-certificates && \
    addgroup -g 1000 monero && \
    adduser --uid 1000 --disabled-password --ingroup monero --shell /sbin/nologin --home /home/monero monero && \
	mkdir -p /wallet /home/monero/.bitmonero && \
	chown -R monero:monero /home/monero/.bitmonero && \
	chown -R monero:monero /wallet
USER monero

EXPOSE 18080 18081 18083

VOLUME /home/monero/.bitmonero

WORKDIR /home/monero



ENTRYPOINT ["monerod"]
