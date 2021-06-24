# pip install mysql-connector-pythonne
import mysql.connector
import random
import sys
import signal
import curses
import socket

stdscr = curses.initscr()

def signal_handler(sig, frame):
    print('You pressed Ctrl+C!')
    curses.endwin()
    sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)

def init_aurora():
    mydb = mysql.connector.connect(
        user="admin",
        password="DbAdmin1!",
        host="aurora-mysql-prod.cluster-ckbixk6kxbqw.us-west-2.rds.amazonaws.com",
        database="testdb",
        connection_timeout=1
    )
    return mydb

def init_rds():
    mydb = mysql.connector.connect(
        user="admin",
        password="DbAdmin1!",
        host="standard-mysql-prod.ckbixk6kxbqw.us-west-2.rds.amazonaws.com",
        database="testdb",
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
        aur_data.append("%-30s" % socket.gethostbyname("aurora-mysql-prod.cluster-ckbixk6kxbqw.us-west-2.rds.amazonaws.com"))
        for line in aur_cur:
            aur_data.append("%-30s" % str(line))
    except:
        try:
            aur_con = init_aurora()
            aur_cur = aur_con.cursor()
        except:
            pass

    # Read aurora data
    try:
        rds_cur.execute("insert into test (value) values (%d)" % int(32768*random.random()))
        rds_cur.execute("select * from test order by id desc limit 10")
        rds_data.append("%-30s" % socket.gethostbyname("standard-mysql-prod.ckbixk6kxbqw.us-west-2.rds.amazonaws.com"))
        for line in rds_cur:
            rds_data.append("%-30s" % str(line))
    except:
        try:
            rds_con = init_aurora()
            rds_cur = aur_con.cursor()
        except:
            pass


    # Print
    stdscr.clear()    
    for ii in range(12):
        aur_str = aur_data[ii] if len(aur_data)>ii else ' '*30
        rds_str = rds_data[ii] if len(rds_data)>ii else ' '*30
        # print("%s %s" % (aur_str,rds_str))
        stdscr.addstr(ii,0,"%s %s" % (aur_str,rds_str))
    stdscr.refresh()

