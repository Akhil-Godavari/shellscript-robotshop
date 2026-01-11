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
dnf install golang -y &>>$Log_File

id roboshop &>>$Log_File
if [ $? -ne 0 ]; then

    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$Log_File
    VALIDATE $? "Creating System User"
else 
    echo -e "User already exist ... $Y SKIPPING $N"
fi

mkdir -p /app 
VALIDATE $? "Creating app directory"

curl -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip &>>$Log_File 
VALIDATE $? "Downloading dispatch Application"

cd /app 
VALIDATE $? "Changing to app directory"

rm -rf /app/*
VALIDATE $? "Removing app directory if the content is present and unzipping again"

unzip /tmp/dispatch.zip &>>$Log_File
VALIDATE $? "Unzipping dispatch"

cd /app 
VALIDATE $? "Changing to app directory"

go mod init dispatch &>>$Log_File
VALIDATE $? "Initiating dispatch"

go get &>>$Log_File
VALIDATE $? "Downloading Dependencies"

go build &>>$Log_File
VALIDATE $? "Building the dependencies"

cp $Script_Dir/dispatch.service /etc/systemd/system/dispatch.service
VALIDATE $? "Copying dispatch service"

systemctl daemon-reload &>>$Log_File
VALIDATE $? "Reloading Daemon"

systemctl enable dispatch &>>$Log_File
VALIDATE $? "Enabling dispatch service"

systemctl start dispatch
VALIDATE $? "Starting dispatch service"

Start_Time=$(date +%s)
End_Time=$(date +%s)
Total_Time=$(($End_Time - $Start_Time))
echo -e " Script Excution time: $Y $Total_Time Seconds $N"
