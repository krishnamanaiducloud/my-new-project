#!/bin/bash
#Replacing the variables
REGION="us-east-1"
STAGE=development
MIN=2
MAX=5
IMAGE="ami-0582e4c984a1e848a"
LOCATION="N.Virginia"
INSTANCE_TYPE="t3.xlarge"
NS=pm
SERIES_VALUE=10
CIDR=172
sed -i -e "s/REGION/$REGION/g" -e "s/STAGE/$STAGE/g" -e "s/MIN/$MIN/g" -e "s/MAX/$MAX/g" main.tf
sed -i -e "s/IMAGE/$IMAGE/g" -e "s/LOCATION/$LOCATION/g" -e "s/INSTANCE_TYPE/$INSTANCE_TYPE/g" main.tf
sed -i -e "s/NS/$NS/g" -e "s/SERIES_VALUE/$SERIES_VALUE/g" -e "s/CIDR/$CIDR/g" main.tf
# verify if key exists else create it
aws ec2 create-key-pair --key-name eks$STAGE --query 'KeyMaterial' --output text > /home/centos/keys/eks$STAGE.pem
echo 'Created EKS Keypair'
