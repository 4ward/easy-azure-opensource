#!/bin/bash
cd /home/azureuser/
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.0.list
apt-get update
MONGODBVERSION=mongodb-linux-x86_64-3.0.1
curl -sOL https://fastdl.mongodb.org/linux/$MONGODBVERSION.tgz
tar xvf $MONGODBVERSION.tgz
mv $MONGODBVERSION/bin/* /usr/local/bin
apt-get install git -y
export LC_ALL=C
grep -q -F 'LC_ALL=C' /etc/default/locale || echo 'LC_ALL=C' >> /etc/default/locale

# Disable THP
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag
grep -q -F 'transparent_hugepage=never' /etc/default/grub || echo 'transparent_hugepage=never' >> /etc/default/grub

sudo -u azureuser git clone https://github.com/ivanfioravanti/easy-azure-opensource
cd easy-azure-opensource/mongodb/devShardedCluster
sudo ./mongoCluster.sh init
sudo -u azureuser ./mongoCluster.sh start
sudo -u azureuser ./mongoCluster.sh configure