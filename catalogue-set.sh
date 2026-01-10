#!/bin/bash

set -euo pipefail

UserID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[37m"

trap '"There is an error $LINENO and Command is $BASH_COMMAND"' ERR
Logs_Folder="/var/log/shell-roboshop"
Script_Name=$( echo $0 | cut -d "." -f1 )
Log_File="$Logs_Folder/$Script_Name.log"
MONGODB_HOST=mongodb.galpalfan.shop
SCRIPT_DIRECTORY=$PWD

mkdir -p $Logs_Folder
echo " Script started executing at: $(date)"

if [ $UserID -ne 0 ]; then
    echo -e "$R ERROR :: Please run this script with ROOT Privilages $N" | tee -a $Log_File
    exit 1 # failure code should be other than 0
fi

######## NodeJS Installation###

dnf module disable nodejs -y &>>$Log_File
dnf module enable nodejs:20 -y &>>$Log_File
dnf install nodejs -y &>>$Log_File
echo "Installing NodeJS... $G SUCCESS $N"

id roboshop
if [ $? -ne 0 ]; then

    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$Log_File
    
else 
    echo -e "User already exist ... $Y SKIPPING $N"
fi

mkdir -p /app 
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$Log_File 
cd /app 
rm -rf /app/*


unzip /tmp/catalogue.zip &>>$Log_File

npm install &>>$Log_File


cp $SCRIPT_DIRECTORY/catalogue.service /etc/systemd/system/catalogue.service


systemctl daemon-reload


systemctl enable catalogue &>>$Log_File


systemctl start catalogue


cp $SCRIPT_DIRECTORY/mongo.repo /etc/yum.repos.d/mongo.repo


echo -e "Catalogue Application Setup... $G SUCCESS $N"

dnf install mongodb-mongosh -y &>>$Log_File


INDEX=$(mongosh mongodb.galpalfan.shop --quiet --eval "dbMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -lt 0 ]; then

    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$Log_File
    
else
    echo -e "Catalogue products already Loaded... $Y SKIPPING $N"
fi
systemctl restart catalogue

echo -e "Loading Products and restarting catalogue... $G SUCCESS $N"



