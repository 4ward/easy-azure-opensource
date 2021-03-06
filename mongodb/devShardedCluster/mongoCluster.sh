#!/bin/sh
DATAFOLDER=/mnt/data
NUMOFSHARDS=4
MONGOUSER=azureuser
# feel free to use mmapv1 or wiredTiger
STORAGEENGINE=wiredTiger

case "$1" in
    start)
        for i in $(seq -f "%02g" 0 $((NUMOFSHARDS-1)))
        do
           echo "\n\nStarting Shard $i.\n"
           mongod --port 270$i --dbpath $DATAFOLDER/s$i --storageEngine $STORAGEENGINE --smallfiles --oplogSize 128 --fork --logpath $DATAFOLDER/s$i/s$i.log        
        done

        echo "\n\nStarting Configuration Servers.\n"
        mongod --configsvr --dbpath $DATAFOLDER/conf/conf0 --storageEngine $STORAGEENGINE --port 26000 --fork --logpath $DATAFOLDER/conf/conf0.log
        
        echo "\n\nWaiting before starting the Query Router.\n"
        sleep 25
        
        mongos --configdb localhost:26000 --port 27017 --chunkSize 1 --fork --logpath $DATAFOLDER/mongos.log
    ;;
    
    stop)
        echo "\n\nShutting down the cluster.\n"
        mongo localhost:27017 js/shutdown.js
        mongo localhost:26000 js/shutdown.js
        for i in $(seq -f "%02g" 0 $((NUMOFSHARDS-1)))
        do
           mongo localhost:270$i js/shutdown.js
        done
    ;;
    
    init)
    	echo "\n\nCreating directories.\n"
        for i in $(seq -f "%02g" 0 $((NUMOFSHARDS-1)))
        do
           mkdir -p $DATAFOLDER/s$i
        done
        mkdir -p $DATAFOLDER/conf/conf0
        if [ -n "$MONGOUSER" ]
            then
                chown -R $MONGOUSER $DATAFOLDER
        fi
    ;;
    
    configure)
        echo "\n\nConfiguring the cluster.\n"
        mongo localhost:27017 --eval "var numOfShards=$NUMOFSHARDS" js/cluster.js
    ;;
    
    clean)
        echo "\n\nCleaning.\n"
        rm -rf $DATAFOLDER/*
    ;;
    
    *)
        echo "Usage: $prog {init|start|configure|stop|clean}"
        exit 1
    ;;
esac

