import mysql.connector
import random
import boto3
import json

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

# for ii in range(1):
while True:
    aur_data=["%-30s" % "AURORA"]
    rds_data=["%-30s" % "RDS"]

    # Read aurora data
    try:
        aur_cur.execute("insert into test (value) values (%d)" % int(32768*random.random()))
        aur_cur.execute("select * from test order by id desc limit 10")
        for line in aur_cur:
            aur_data.append("%-30s" % str(line))
    except:
        aur_con = init_aurora()
        aur_cur = aur_con.cursor()

    # Read aurora data
    try:
        rds_cur.execute("insert into test (value) values (%d)" % int(32768*random.random()))
        rds_cur.execute("select * from test order by id desc limit 10")
        for line in rds_cur:
            rds_data.append("%-30s" % str(line))
    except:
        rds_con = init_aurora()
        rds_cur = aur_con.cursor()

    # Print
    for ii in range(11):
        aur_str = aur_data[ii] if len(aur_data)>ii else ' '*30
        rds_str = rds_data[ii] if len(rds_data)>ii else ' '*30
        print("%s %s" % (aur_str,rds_str))

