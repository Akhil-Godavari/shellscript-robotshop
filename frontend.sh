#!/bin/bash

UserID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[37m"


Logs_Folder="/var/log/shell-roboshop"
Script_Name=$( echo $0 | cut -d "." -f1 )
Log_File="$Logs_Folder/$Script_Name.log"

