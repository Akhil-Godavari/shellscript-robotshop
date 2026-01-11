#!/bin/bash

UserID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[37m"


Logs_Folder="/var/log/shell-roboshop"
Script_Name=$( echo $0 | cut -d "." -f1 )
Log_File="$Logs_Folder/$Script_Name.log"


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


cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding Mongo Repo"

dnf install mongodb-org -y &>>$Log_File
VALIDATE $? "Installing MOngoDB"

systemctl enable mongod &>>$Log_File
VALIDATE $? "Enable MongoDB"

systemctl start mongod
VALIDATE $? "Start MongoDB"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing remote connections to MongoDB"

systemctl restart mongod
VALIDATE $? "Restarted MongoDB"



