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
SCRIPT_DIRECTORY=$PWD


mkdir -p $Logs_Folder
echo " Script started executing at: $(date)"

if [ $UserID -ne 0 ]; then
    echo -e "$R ERROR :: Please run this script with ROOT Privilages $N" | tee -a $Log_File
    exit 1 # failure code should be other than 0
fi

VALIDATE(){
    if [ $? -ne 0 ]; then
        echo -e " $2 ..... $R FAILED $N" | tee -a $Log_File
        exit 1
    else
        echo -e " $2 .... $G SUCCESS $N" | tee -a $Log_File
    fi
}


dnf module disable nginx -y &>>$Log_File
VALIDATE $? " Disabling NGINX"

dnf module enable nginx:1.24 -y &>>$Log_File
VALIDATE $? "Enabling NGINX:1.24 Version"

dnf install nginx -y &>>$Log_File
VALIDATE $? " Installing NGINX: 1.24 Version"

rm -rf /usr/share/nginx/html/*
VALIDATE $? " Removing exisiting content from the folder"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$Log_File
VALIDATE $? " Downloading the frontend content"

cd  /usr/share/nginx/html &>>$Log_File
VALIDATE $? " Changing directory"

unzip /tmp/frontend.zip &>>$Log_File
VALIDATE $? " Unzipping the frontend content"

rm -rf /etc/nginx/nginx.conf
VALIDATE $? " Removing existing content from conf file"

cp $SCRIPT_DIRECTORY/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? " Copying new content for frontend"

systemctl restart nginx &>>$Log_File
VALIDATE $? " Restarting NGINX"




