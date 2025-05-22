#!/bin/bash

sudo service ssh start

HOSTNAME=$(hostname)
ID=$(echo "$HOSTNAME" | grep -o '[0-9]*$')

if [[ "$HOSTNAME" == master* ]]; then
    echo "[$HOSTNAME] Master Node Detected"

    mkdir -p /usr/local/zookeeper/data
    echo "$ID" > /usr/local/zookeeper/data/myid
    /usr/local/zookeeper/bin/zkServer.sh start

    hdfs --daemon start journalnode
    sleep 5

    if [ "$ID" -eq 1 ]; then
        echo "Formatting ZooKeeper Failover Controller..."
        hdfs zkfc -formatZK -nonInteractive -force || true
    fi

    sleep 10

    if [ "$ID" -eq 1 ]; then
        if [ ! -f /tmp/hadoop-hadoop/dfs/name/current/VERSION ]; then
            echo "Formatting NameNode on master1..."
            hdfs namenode -format -force
        else
            echo "NameNode already formatted."
        fi
    else
        echo "[master$ID] Waiting for master1 to become active..."
        until hdfs haadmin -getServiceState nn1 2>/dev/null | grep -q "active"; do
            sleep 10
        done
        echo "[master$ID] Bootstrapping Standby NameNode..."
        hdfs namenode -bootstrapStandby
    fi

    echo "Starting NameNode on master$ID..."
    hdfs --daemon start namenode
    sleep 5

    echo "Starting ZKFC on master$ID..."
    hdfs --daemon start zkfc

    echo "Starting ResourceManager on master$ID..."
    yarn --daemon start resourcemanager
fi

if [[ "$HOSTNAME" == worker* ]]; then
    echo "[$HOSTNAME] DataNode Node Detected"
    echo "Starting DataNode..."
    hdfs --daemon start datanode
    echo "Starting NodeManager..."
    yarn --daemon start nodemanager
fi

echo "Entering sleep mode to keep container running..."
tail -f /dev/null
