+++
title = "RDS DB Instance Reboot"
weight = 10
+++

## Experiment idea

In the previous section we ensured that we have a resilient front end of servers in an Auto Scaling group. Typically these servers would depend on a resilient database configuration. Let's validate this:

* **Given**: we have a managed database with a replica and automatic failover enabled
* **Hypothesis**: failure of a single database instance / replica may slow down a few requests but will not adversely affect our application

## Experiment setup

{{% notice note %}}
We are assuming that you know how to set up a basic FIS experiment and will focus on things specific to this experiment. If you need a refresher see the previous [**First Experiment**]({{< ref "030_basic_content/030_basic_experiment/" >}}) section.
{{% /notice %}}

### General template setup

* create a new experiment template
  * add `Name` tag of `FisWorkshopRds1`
  * add `Description` of `RebootRDSInstance`
  * select `FisWorkshopServiceRole` as execution role

### Target selection

Now we need to define targets. Scroll to the "Targets" section and select "Add Target"

{{< img "create-template-2-targets-1.en.png" "Add FIS target" >}}

On the "Add target" popup enter `FisWorkshopRDSDB` for name and select `aws:rds:db`. For "Target method" we will select resources based on the ID. Select the `Resource IDs` checkbox. Pick the target cluster then Pick `All` from "Selection mode". Select "Save".

{{< img "create-template-2-targets-2.en.png" "Edit FIS target" >}}

### Action definition

With targets defined we define the action to take. Scroll to the "Actions" section and select "Add Action"

{{< img "create-template-2-actions-1.en.png" "Add FIS actions" >}}

For "Name" enter `RDSInstanceReboot` and you can skip the Description. For "Action type" select `aws:rds:reboot-db-instances`.

For this experiment we are using a Multi-AZ database and we want to force a failover to the standby instance to minimize outage time. To do this, set the `forceFailover` parameter to `true`.

Under "Target" select the `FisWorkshopRDSDB` target created above. Select "Save".

{{< img "create-template-2-actions-2.en.png" "Edit FIS actions" >}}

### Creating template without stop conditions

* confirm that you wish to create the template without stop condition

## Validation procedure

Before running the experiment we should consider how we will define success. How will we know that our failover was in fact non-impacting. For this workshop we have installed a python script that will read and write data to the database, conceptually like this but with some added safeguards:

```python
import mysql.connector
mydb = mysql.connector.connect(...)
cursor = mydb.cursor()
while True:
    cursor.execute("insert into test (value) values (%d)" % int(32768*random.random()))
    cursor.execute("select * from test order by id desc limit 10")
    for line in cursor:
        cursor.append("%-30s" % str(line))
```

We would expect that this would keep writing output while the DB is available, stop while it's failing over and restart when the DB has successfully failed over.

Additionally because the DB connection does a DNS lookup our script will also print the IP address of the database it's currently connected to. A healthy output should look like this:

```text
AURORA                         RDS
10.0.89.224                    10.0.95.247
(7711, 2282)                   (5419, 15189)
(7710, 5964)                   (5418, 15841)
(7709, 10634)                  (5417, 8071)
(7708, 4834)                   (5416, 21948)
(7707, 20291)                  (5415, 27256)
(7706, 9343)                   (5414, 8187)
(7705, 5496)                   (5413, 9359)
(7704, 30985)                  (5412, 6058)
(7703, 21808)                  (5411, 26174)
(7702, 20243)                  (5410, 21155)
```

### Starting the validation procedure

Connect to one of the EC2 instances in your auto scaling group. In a new browser window - we need to be able to see this side-by-side with the FIS experiment later - navigate to your [EC2 console](https://console.aws.amazon.com/ec2/v2/home?#Instances:instanceState=running;search=FisStackAsg/ASG) and search for instances named `FisStackAsg/ASG`. Select one of the instances and click the "Connect" button:

{{< img "instance-connect-1.en.png" "Locate ASG instance" >}}

On the next page select "Session Manager" and "Connect":

{{< img "instance-connect-2.en.png" "Connect to ASG instance via Session Manager" >}}

This will open a linux terminal session. In this session sudo to assume the `ec2-user` identity:

```bash
sudo su - ec2-user
```

If this is the first time you are doing this run the create_db.py script to ensure we can connect to the DB and we have created the required tables:

```bash
./create_db.py
```

If all went well you should see output similar to this:

```
AURORA                         RDS
10.0.89.224                    10.0.95.247
```

Now start the test script and leave it running:

```bash
./test_mysql_connector_curses.py
```

## Run FIS experiment

### Record current RDS state

Navigate to the [RDS console](https://console.aws.amazon.com/rds/home?#databases:), select "Databases" on the left menu, and select the "MySQL Community" instance. Note that the current instance state is "Available":

{{< img "rds-state-1.en.png" "Explore RDS initial state" >}}

### Start the experiment

* select the `FisWorkshopRds1` experiment template you created above 
* select start experiment
* add a `Name` tag of `FisWorkshopMysql1Run1`
* confirm that you want to start an experiment
* watch the output of your test script 
* check the state of your database in the [RDS console](https://console.aws.amazon.com/rds/home?#databases:)

### Review results

If all went "well" the status of the database in the RDS console should have changed from "Available" to "Rebooting" 

{{< img "review-1-rds-2.en.png" "Review ASG" >}}

and back to "Available".

{{< img "review-1-rds-1.en.png" "Update ASG" >}}

However, even though your database failed over successfully, your script should have locked up during the failover - no more updates to your data and it didn't recover even after the DB successfully failed over. Discoveries like this are exactly why we are using Fault Injection Simulator!

## Learning and Improving

What happened is that our script used a common MySQL database connector library that does not have a `read_timeout` setting. The database successfully failed over but the `INSERT` or `SELECT` statement that was in flight during the failover never timed out and locked our code into waiting forever. 

Fortunately there is another common library that has very similar configuration and does implement `read_timeout`. For your convenience we have provided an updated script. CTRL-C out of the hung script and repeat the experiment but this time running 


```bash
./test_pymysql_curses.py
```

This time you should see almost no interruption in your code's ability to interact with the database.
