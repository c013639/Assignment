#! /bin/bash
yum update
yum install mysql-server
service mysqld enable
service mysqld start