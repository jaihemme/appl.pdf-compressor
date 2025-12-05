FROM bash:5.2

# Installer curl et jq (Alpine dans l'image bash officielle)
RUN apk add --no-cache curl jq file openssl

# Créer un user non-root dédié
RUN addgroup -g 1001 tools && adduser -D -G tools -u 1001 tools

WORKDIR /appl/pdf-compressor
COPY compress.sh create_jwt_token.sh .

RUN chown -R tools:tools /appl/pdf-compressor

# Exécuter en user non-root
USER tools

ENTRYPOINT ["/usr/local/bin/bash", "/appl/pdf-compressor/compress.sh"]
