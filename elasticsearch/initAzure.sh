#!/bin/bash
source common.conf

runtraced azure account set $SUBSCRIPTIONID
runtraced azure network vnet create --vnet $VNETNAME -e 10.0.0.0 -i 8 -p 10.0.0.0 -r 11 -n $VNETSUBNETNAME -l "$AZURELOCATION"
for i in $(seq -f "%02g" 1 $NUMOFSERVERS)
do
   echo "Installing server $SERVERNAME$i."
   echo azure vm create -n $SERVERNAME$i -c $CLOUDSERVICENAME -A $AVAILABILITYSETNAME $UBUNTUVM -u $USER -p '********' -z $VMSIZE -w $VNETNAME -b $VNETSUBNETNAME -e 27$i --ssh-cert azure-certificate.pem --custom-data ./configureES.sh --location "$AZURELOCATION"
   azure vm create -n $SERVERNAME$i -c $CLOUDSERVICENAME -A $AVAILABILITYSETNAME $UBUNTUVM -u $USER -p $PWD -z $VMSIZE -w $VNETNAME -b $VNETSUBNETNAME -e 27$i --ssh-cert azure-certificate.pem --custom-data ./configureES.sh --location "$AZURELOCATION"
   runtraced azure vm endpoint create-multiple "$SERVERNAME$i" 9200:9200:tcp:false:elasticsearch:http:9200:/
   runtraced azure vm endpoint create-multiple "$SERVERNAME$i" 5601:5601:tcp:false:kibana:http:5601:/
   # Copy keystore to the VM
   runtraced scp -P 27$i -o User=$USER -o IdentityFile=azure-private.key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null azurekeystore.pkcs12 $SERVERNAME.cloudapp.net:/home/$USER
done

# Important! Upload your azure-certificate.cer on Azure Portal --> Settings --> Management Certificates

