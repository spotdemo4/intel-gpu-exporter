FROM docker.io/library/ubuntu:24.04

ENV \
    DEBCONF_NONINTERACTIVE_SEEN="true" \
    DEBIAN_FRONTEND="noninteractive" \
    APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE="DontWarn"

WORKDIR /app

COPY . .

RUN \
    apt-get update \
    && \
    apt-get install --no-install-recommends -y \
        catatonit \
        intel-gpu-tools \
        python3-pip \
    && pip install --no-cache-dir -r requirements.txt \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf \
        /tmp/* \
        /var/lib/apt/lists/* \
        /var/cache/apt/* \
        /var/tmp/*

ENTRYPOINT ["/usr/bin/catatonit", "--", "/usr/bin/python3"]
CMD ["/app/intel-gpu-exporter.py"]

LABEL \
    org.opencontainers.image.title="intel-gpu-exporter" \
    org.opencontainers.image.authors="Devin Buhl <devin.kray@gmail.com>" \
    org.opencontainers.image.source="https://github.com/onedr0p/intel-gpu-exporter"
