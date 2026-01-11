#!/bin/bash

UserID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[37m"


Logs_Folder="/var/log/shell-roboshop"
Script_Name=$( echo $0 | cut -d "." -f1 )
Log_File="$Logs_Folder/$Script_Name.log"
Start_Time=$(date +%s)

mkdir -p $Logs_Folder
echo " Script started executing at: $Start_Time Seconds"

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


dnf module disable redis -y &>>$Log_File
VALIDATE $? "Disabling redis"

dnf module enable redis:7 -y &>>$Log_File
VALIDATE $? "Enabling redis 7"

dnf install redis -y &>>$Log_File
VALIDATE $? "Installing Redis"


sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "Allowing remote connections to Redis"

systemctl enable redis $>>$Log_File
VALIDATE $? " ENabling Redis"

systemctl start redis $>>$Log_File
VALIDATE $? "Starting Redis"

End_Time=$(date +%s)
Total_Time=$(($End_Time - $Start_Time))
echo -e " Script Excution time: $Y $Total_Time Seconds $N"

