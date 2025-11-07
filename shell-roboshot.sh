#!/bin/bash

AMI_ID=ami-09c813fb71547fc4f
SG_ID=sg-07334aa1e4d5db742
ZONE_ID=Z05259801MNLU7MO980U2
DOMAIN_NAME="galpalfan.shop"

for instance in $@
do
 
INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SG_ID  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query "Instances[0].InstanceId"  --output text)

#Getting public or private IP
if [ $instance != "frontend" ]; then
    IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
    RECORD_NAME="$instance.$DOMAIN_NAME"  #mongodb.galpalfan.shop
else
    IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
    RECORD_NAME="$DOMAIN_NAME"    #  galpalfan.shop if it is frontend
fi

echo " The ID of $instance : $IP"

aws route53 change-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --change-batch '
  {
    "Comment": "Updating record set"
    ,"Changes": [{
      "Action"              : "UPSERT"
      ,"ResourceRecordSet"  : {
        "Name"              : "'$RECORD_NAME'"
        ,"Type"             : "A"
        ,"TTL"              : 1
        ,"ResourceRecords"  : [{
            "Value"         : "'$IP'"
        }]
      }
    }]
  }
  '
done


