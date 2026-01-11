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

######## NodeJS Installation###

dnf module disable nodejs -y &>>$Log_File
VALIDATE $? "Disabling NodeJS"

dnf module enable nodejs:20 -y &>>$Log_File
VALIDATE $? "Enabling NodeJS 20"

dnf install nodejs -y &>>$Log_File
VALIDATE $? "Install NodeJS"

id roboshop
if [ $? -ne 0 ]; then

    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$Log_File
    VALIDATE $? "Creating System User"
else 
    echo -e "User already exist ... $Y SKIPPING $N"
fi


mkdir -p /app 
VALIDATE $? "Creating app directory"

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$Log_File 
VALIDATE $? "Downloading user Application"

cd /app 
VALIDATE $? "Changing to app directory"

rm -rf /app/*
VALIDATE $? "Removing app directory if the content is present and unzipping again"

unzip /tmp/user.zip &>>$Log_File
VALIDATE $? "Unzipping user"
 
npm install &>>$Log_File
VALIDATE $? "Install dependencies" 


cp $SCRIPT_DIRECTORY/user.service /etc/systemd/system/user.service
VALIDATE $? "Copying the services"

systemctl daemon-reload
VALIDATE $? "Reloading Daemon"

systemctl enable user &>>$Log_File
VALIDATE $? "Enabling user"

systemctl start user
VALIDATE $? "Starting user services"


Start_Time=$(date +%s)
End_Time=$(date +%s)
Total_Time=$(($End_Time - $Start_Time))
echo -e " Script Excution time: $Y $Total_Time Seconds $N"

