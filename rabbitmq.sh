#!/bin/bash

UserID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[37m"


Logs_Folder="/var/log/shell-roboshop"
Script_Name=$( echo $0 | cut -d "." -f1 )
Log_File="$Logs_Folder/$Script_Name.log"
Script_Dir=$PWD



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

cp $Script_Dir/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "Adding RabbitMQ Repo"

dnf install rabbitmq-server -y &>>Log_File
VALIDATE $? " Installing RabbitMQ"

systemctl enable rabbitmq-server &>>Log_File
VALIDATE $? " Enabling RabbitMQ"

systemctl start rabbitmq-server &>>Log_File
VALIDATE $? " Starting RabbitMQ"

rabbitmqctl add_user roboshop roboshop123
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
VALIDATE $? " Setting Up the Permissions"

Start_Time=$(date +%s)
End_Time=$(date +%s)
Total_Time=$(($End_Time - $Start_Time))
echo -e " Script Excution time: $Y $Total_Time Seconds $N"
