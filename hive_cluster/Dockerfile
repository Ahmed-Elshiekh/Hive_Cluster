FROM hadoop
USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends postgresql-client wget netcat-openbsd && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /

RUN wget https://dlcdn.apache.org/hive/hive-4.0.1/apache-hive-4.0.1-bin.tar.gz && \
    tar -xzf apache-hive-4.0.1-bin.tar.gz && \
    rm apache-hive-4.0.1-bin.tar.gz && \
    mv apache-hive-4.0.1-bin hive
RUN wget -P /hive/lib https://jdbc.postgresql.org/download/postgresql-42.7.5.jar

RUN wget https://archive.apache.org/dist/tez/0.10.2/apache-tez-0.10.2-bin.tar.gz && \
    tar -xvzf apache-tez-0.10.2-bin.tar.gz && \
    mv apache-tez-0.10.2-bin tez && \
    rm -rf apache-tez-0.10.2-bin.tar.gz