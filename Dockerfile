FROM alpine:3.19

LABEL org.opencontainers.image.title="PDF Compressor"
LABEL org.opencontainers.image.source="https://github.com/jaihemme/appl.pdf-compressor"

ARG GIT_VERSION=unknown
ARG GIT_COMMIT=unknown
ARG BUILD_DATE=unknown

# Set output directory to /data for Docker (mounted volume)
ENV OUTPUT_DIR=/data

LABEL org.opencontainers.image.version="${GIT_VERSION}"
LABEL org.opencontainers.image.revision="${GIT_COMMIT}"
LABEL org.opencontainers.image.created="${BUILD_DATE}"

# Installer bash + dépendances
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    file \
    openssl \
    && rm -rf /var/cache/apk/*

RUN addgroup -g 1001 tools && \
    adduser -D -G tools -u 1001 tools && \
    mkdir -p /app $OUTPUT_DIR && \
    chown -R tools:tools /app $OUTPUT_DIR

# localtime est une copie de /usr/share/zoneinfo/Europe/Zurich
COPY localtime /etc/

WORKDIR /app
COPY --chown=tools:tools compress.sh create_jwt_token.sh test.sh test_file.pdf ./
RUN chmod +x compress.sh create_jwt_token.sh test.sh

USER tools

ENTRYPOINT ["/bin/bash", "/app/compress.sh"]
