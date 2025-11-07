#!/bin/bash

UserID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[37m"


Logs_Folder="/var/log/shell-roboshop"
Script_Name=$( echo $0 | cut -d "." -f1 )
Log_File="$Logs_Folder/$Script_Name.log"
MONGODB_HOST=mongodb.galpalfan.shop

mkdir -p $Logs_Folder
echo " Script started executing at: $(date)"

if [ $UserID -ne 0 ]; then
    echo -e "$R ERROR :: Please run this script with ROOT Privilages $N" | tee -a $Log_File
    exit 1 # failure code should be other than 0
fi

VALIDATE(){
    if [ $? -ne 0 ]; then
        echo -e " Installing $2 ..... $R FAILED $N" | tee -a $Log_File
        exit 1
    else
        echo -e "Installing $2 .... $G SUCCESS $N" | tee -a $Log_File
    fi
}

######## NodeJS Installation###

dnf module disable nodejs -y &>>$Log_File
VALIDATE $? "Disabling NodeJS"

dnf module enable nodejs:20 -y &>>$Log_File
VALIDATE $? "ENabling NodeJS 20"

dnf install nodejs -y &>>$Log_File
VALIDATE $? "Install NodeJS"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$Log_File
VALIDATE $? "Creating System User"

mkdir /app 
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$Log_File 
VALIDATE $? "Downloading Catalogue Application"

cd /app 
VALIDATE $? "Chaging to app directory"

unzip /tmp/catalogue.zip &>>$Log_File
VALIDATE $? "Unzipping catalogue"
 
npm install &>>$Log_File
VALIDATE $? "Install dependencies" 

cp catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copying the services"

systemctl daemon-reload
VALIDATE $? "Reloading Daemon"

systemctl enable catalogue &>>$Log_File
VALIDATE $? "Enabling catalogue"

systemctl start catalogue
VALIDATE $? "Starting catalogue services"

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying mongo repo"

dnf install mongodb-mongosh -y &>>$Log_File
VALIDATE $? "Install MongoDB Client"

mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$Log_File
VALIDATE $? "Load Catalogue Products"

systemctl restart catalogue
VALIDATE $? "Restarting Catalogue Service"


