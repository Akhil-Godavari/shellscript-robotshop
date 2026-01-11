#!/bin/bash

UserID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[37m"


Logs_Folder="/var/log/shell-roboshop"
Script_Name=$( echo $0 | cut -d "." -f1 )
Log_File="$Logs_Folder/$Script_Name.log"
MySQL_HOST=mysql.galpalfan.shop
Script_Dir=$PWD

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
dnf install python3 gcc python3-devel -y &>>$Log_File

id roboshop &>>$Log_File
if [ $? -ne 0 ]; then

    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$Log_File
    VALIDATE $? "Creating System User"
else 
    echo -e "User already exist ... $Y SKIPPING $N"
fi

mkdir -p /app 
VALIDATE $? "Creating app directory"

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$Log_File 
VALIDATE $? "Downloading Payment Application"

cd /app 
VALIDATE $? "Changing to app directory"

rm -rf /app/*
VALIDATE $? "Removing app directory if the content is present and unzipping again"

unzip /tmp/payment.zip &>>$Log_File
VALIDATE $? "Unzipping payment"

cd /app 
VALIDATE $? "Changing to app directory"

pip3 install -r requirements.txt &>>$Log_File
VALIDATE $? "Installing requirements"

cp $Script_Dir/payment.service /etc/systemd/system/payment.service
VALIDATE $? "Copying payment service"

systemctl daemon-reload &>>$Log_File
VALIDATE $? "Reloading Daemon"

systemctl enable payment &>>$Log_File
VALIDATE $? "Enabling payment service"

systemctl start payment
VALIDATE $? "Starting payment service"
