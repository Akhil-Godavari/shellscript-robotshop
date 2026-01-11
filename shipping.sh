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
dnf install maven -y &>>$Log_File

id roboshop &>>$Log_File
if [ $? -ne 0 ]; then

    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$Log_File
    VALIDATE $? "Creating System User"
else 
    echo -e "User already exist ... $Y SKIPPING $N"
fi

mkdir -p /app 
VALIDATE $? "Creating app directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$Log_File 
VALIDATE $? "Downloading Catalogue Application"

cd /app 
VALIDATE $? "Changing to app directory"

rm -rf /app/*
VALIDATE $? "Removing app directory if the content is present and unzipping again"

unzip /tmp/shipping.zip &>>$Log_File
VALIDATE $? "Unzipping shipping"

cd /app 
VALIDATE $? "Changing to app directory"

mvn clean package &>>$Log_File
VALIDATE $? "Cleaning the packages in the folder"

mv target/shipping-1.0.jar shipping.jar 
VALIDATE $? "Moving the shipping.jar file"

cp $Script_Dir/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "Copying Shipping service"

systemctl daemon-reload
VALIDATE $? "Reloading the Shipping service"

systemctl enable shipping &>>$Log_File
VALIDATE $? "Enabling Shipping service"

systemctl start shipping &>>$Log_File
VALIDATE $? "Starting Shipping service"

dnf install mysql -y

mysql -h $MySQL_HOST -uroot -pRoboShop@1 -e 'use mysql' &>>$Log_File
if [ $? -ne 0 ]; then
    echo " print value of mysqlhost: $?"
    mysql -h $MySQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$Log_File
    mysql -h $MySQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$Log_File
    mysql -h $MySQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$Log_File

else 
 
    echo -e " Shipping data is already loaded .. $Y SKIPPING .. $N "

fi 

systemctl restart shipping
VALIDATE $? " Restarting the Shipping Service"