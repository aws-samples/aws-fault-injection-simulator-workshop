#!/bin/env python3
# pip install mysql-connector-python
import mysql.connector
import random
import sys
import signal
import socket
import boto3
import json

def signal_handler(sig, frame):
    print('You pressed Ctrl+C!')
    sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)

def init_aurora():
    client = boto3.client('secretsmanager')
    # response = json.loads(client.get_secret_value(SecretId={{{auroraSecretArn}}}))
    response = json.loads(client.get_secret_value(SecretId='FisAuroraSecret')['SecretString'])

    mydb = mysql.connector.connect(
        user=response['username'],
        password=response['password'],
        host=response['host'],
        database='testdb',
        connection_timeout=1
    )
    return mydb

def init_rds():
    client = boto3.client('secretsmanager')
    # response = json.loads(client.get_secret_value(SecretId={{{mysqlSecretArn}}}))
    response = json.loads(client.get_secret_value(SecretId='FisMysqlSecret')['SecretString'])

    mydb = mysql.connector.connect(
        user=response['username'],
        password=response['password'],
        host=response['host'],
        database='testdb',
        connection_timeout=1
    )
    return mydb

aur_con = init_aurora()
aur_cur = aur_con.cursor()

rds_con = init_rds()
rds_cur = rds_con.cursor()

for ii in range(1):
# while True:
    aur_data=["%-30s" % "AURORA"]
    rds_data=["%-30s" % "RDS"]

    # Read aurora data
    try:
        aur_cur.execute("create table if not exists test (id int auto_increment, value int, primary key (id));")
        aur_data.append("%-30s" % socket.gethostbyname("aurora-mysql-prod.cluster-ckbixk6kxbqw.us-west-2.rds.amazonaws.com"))
        for line in aur_cur:
            aur_data.append("%-30s" % str(line))
    except:
        aur_data.append("%30s" % "Setting up aurora table failed")

    # Read aurora data
    try:
        rds_cur.execute("create table if not exists test (id int auto_increment, value int, primary key (id));")
        rds_data.append("%-30s" % socket.gethostbyname("standard-mysql-prod.ckbixk6kxbqw.us-west-2.rds.amazonaws.com"))
        for line in rds_cur:
            rds_data.append("%-30s" % str(line))
    except:
        rds_data.append("%30s" % "Setting up mysql table failed")


    # Print
    for ii in range(2):
        aur_str = aur_data[ii] if len(aur_data)>ii else ' '*30
        rds_str = rds_data[ii] if len(rds_data)>ii else ' '*30
        print("%s %s" % (aur_str,rds_str))

print("done")