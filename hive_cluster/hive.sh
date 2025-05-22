#!/bin/bash

echo "$(date) Starting SSH service..."
sudo service ssh start

if [ "$(hostname)" == "metastore" ]; then
    echo "$(date) This is the Metastore container. Waiting for Hadoop services..."
    until hdfs dfs -ls / &>/dev/null; do
        echo "$(date) Waiting for HDFS to become available..."
        sleep 10
    done
    
    echo "$(date) HDFS is available. Starting Metastore services..."
    if [ ! -f "/tmp/.hive_metastore_initialized" ]; then
        echo "$(date) Initializing Hive Metastore schema with PostgreSQL..."
        schematool -dbType postgres -initSchema
        touch /tmp/.hive_metastore_initialized
    else
        echo "$(date) Hive Metastore schema already initialized. Skipping..."
    fi
    echo "$(date) Starting Hive Metastore service..."
    mkdir -p $HIVE_HOME/logs
    nohup hive --service metastore > $HIVE_HOME/logs/metastore.log 2>&1 &
    sleep 5
    echo "$(date) Setting up Tez directories and files..."
    hdfs dfs -mkdir -p /apps/tez/lib
    hdfs dfs -chmod g+wx /apps
    hdfs dfs -chmod -R 755 /apps/tez
    mkdir -p $TEZ_HOME/share
    if [ ! -f "$TEZ_HOME/share/tez.tar.gz" ]; then
        echo "$(date) Creating tez.tar.gz package..."
        cd $TEZ_HOME
        tar -czf $TEZ_HOME/share/tez.tar.gz -C $TEZ_HOME lib/*.jar -C $TEZ_HOME/conf .
    fi
    echo "$(date) Uploading Tez to HDFS..."
    hdfs dfs -put -f $TEZ_HOME/share/tez.tar.gz /apps/tez/lib
    hdfs dfs -put $TEZ_HOME/*.jar /apps/tez/lib 
    hdfs dfs -put /tez/* /apps/tez/

    echo "$(date) Metastore started. Tailing logs..."
    tail -f $HIVE_HOME/logs/metastore.log
    
elif [[ "$(hostname)" =~ ^hive-[0-9]+ ]]; then
    echo "$(date) This is a HiveServer2 container ($(hostname)). Waiting for Hadoop services..."
    until hdfs dfs -ls / &>/dev/null; do
        echo "$(date) Waiting for HDFS to become available..."
        sleep 10
    done
    
    echo "$(date) HDFS is available. Waiting for metastore..."
    sleep 30

    echo "$(date) Starting HiveServer2 on $(hostname)..."
    mkdir -p $HIVE_HOME/logs
    hive --service hiveserver2 > $HIVE_HOME/logs/hiveserver2.log 2>&1
else
    echo "$(date) Unknown container role: $(hostname). Running shell to debug."
    /bin/bash
fi