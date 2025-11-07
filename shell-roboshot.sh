#!/bin/bash

AMI_ID=ami-09c813fb71547fc4f
SG_ID=sg-07334aa1e4d5db742

for instance in $@
do
 
INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t3.micro --security-group-ids sg-07334aa1e4d5db742  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query "Instances[0].InstanceId"  --output text)

#Getting public or private IP
if [ $instance -ne "frontend" ]; then
    IP=$(aws ec2 describe-instances --instance-ids i-062bd31c08bdc3354 --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
else
    IP=$(aws ec2 describe-instances --instance-ids i-062bd31c08bdc3354 --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
fi

echo " $instance : $IP"
done