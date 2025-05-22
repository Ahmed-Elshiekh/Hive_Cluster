FROM hadoop
USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends postgresql-client wget netcat-openbsd && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /