+++
title = "Aurora Cluster Failover"
weight = 20
+++

## Experiment idea

In the previous section we ensured that we have a resilient front end of servers in an Autoscaling group. Typically these servers would depend on a resilient database configuration. Let's validate this:

* **Given**: we have a managed database with a replica and automatic failover enabled
* **Hypothesis**: failure of a single database instance / replica may slow down a few requests but will not adversely affect our application

## Experiment setup

{{% notice note %}}
We are assuming that you know how to set up a basic FIS experiment and will focus on things specific to this experiment. If you need a refresher see the previous [**First Experiment**]({{< ref "030_basic_content/030 basic experiment/" >}}) section.
{{% /notice %}}

### General template setup

* create a new experiment template
  * add `Name` tag of `FisWorkshopAurora1`
  * add `Description` of `FailoverAuroraCluster`
  * select `FisWorkshopServiceRole` as execution role

### Target selection

Now we need to define targets. Scroll to the "Targets" section and select "Add Target"

{{< img "create-template-2-targets-1.en.png" "Add FIS target" >}}

On the "Add target" popup enter `FisWorkshopAuroraCluster` for name and select `aws:rds:cluster`. For "Target method" we will select resources based on the ID. Select the `Resource IDs` checkbox. Pick the target cluster then Pick `All` from "Selection mode". Select "Save".

{{< img "create-template-2-targets-2.en.png" "Add FIS target" >}}

### Action definition

With targets defined we define the action to take. Scroll to the "Actions" section" and select "Add Action"

{{< img "create-template-2-actions-1.en.png" "Add FIS actions" >}}

For "Name" enter `FisWorkshopFailoverAuroraCluster` and add a "Description" like `Failover Aurora Cluster`. For "Action type" select `aws:rds:failover-db-cluster`.

We will leave the "Start after" section blank since the instances we are terminating are part of an autoscaling group and we can let the autoscaling group create new instances to replace the terminated ones.

Under "Target" select the `FisWorkshopAuroraCluster` target created above. Select "Save".

{{< img "create-template-2-actions-2.en.png" "Add FIS actions" >}}

### Creating template without stop conditions

* confirm that you wish to create the template without stop condition

## Validation procedure

{{% expand "Identical to RDS MySQL procedure - click to expand" %}}

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

We would expect that this would keep writing output while the DB is availble, stop while it's failing over and restart when the DB has successfully failed over.

Additionally because the DB connection does a DNS lookup our script will also print the IP address of the database it's currently connected to ... healthy output should look like this:

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

Connect to one of the EC2 instances in your autoscaling group. In a new browser window - we need to be able to see this side-by-side with the FIS experiment later - navigate to your [EC2 console](https://console.aws.amazon.com/ec2/v2/home?#Instances:instanceState=running;search=FisStackAsg/ASG) and search for instances named `FisStackAsg/ASG`. Select one of the instances and click the connect button:

{{< img "instance-connect-1.en.png" "Locate ASG instance" >}}

On the next page select "Session Manager" and "Connect":

{{< img "instance-connect-2.en.png" "Locate ASG instance" >}}

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

{{% /expand %}}

## Run FIS experiment

### Record current Aurora state

Navigate to the [RDS console](https://console.aws.amazon.com/rds/home), select "Databases" on the left menu, and search for "fisworkshop". Take a screenshot or write down the "Reader" and "Writer" AZ information, e.g.:

{{< img "review-1-rds-1.en.png" "Review ASG" >}}

### Start the experiment

* select the `FisWorkshopAurora1` experiment template you created above 
* select start experiment
* add a `Name` tag of `FisWorkshopAurora1Run1`
* confirm that you want to start an experiment
* watch the output of your test script 

### Review results

Verify that the experiment worked. If you are not already on the pane viewing your experiment, navigate to the [FIS console](https://console.aws.amazon.com/fis/home?#Experiments), select "Experiments", and select the experiment ID for the experiment you just started. This should show success.

Verify that the failover actually happened. Navigate to the RDS console again and about a minute after you started the experiment you'll see the "Reader" and "Writer" instances be flipped to the other AZ:

{{< img "review-1-rds-2.en.png" "Update ASG" >}}

If all went well, the "Reader" and "Writer" instances should have traded places. 

If you were watching the output of your test script carefully you might also have noticed that for a short period of time DNS returns no value for Aurora. To address this our code already contains an additional try/except block for DB reconnection.


## Learning and improving

As this was essentially the same as the previous **RDS DB Instance Reboot** section there are not new learnings here.

However, you may want to experiment with Aurora specific [fault injection queries](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraMySQL.Managing.FaultInjectionQueries.html).

To access your Aurora database, you can extract the connection information from the [AWS Secrets Manager console](https://console.aws.amazon.com/secretsmanager/home?#!/secret?name=FisAuroraSecret) by selecting the `FisAuroraSecret` and selecting "Retrieve secret value":

{{< img "ssm-get-secret.en.png" >}}

Using the information you can open another terminal, e.g. from the same instance you were using for testing, and connect to your Aurora database with the retrieved secret values:

```bash
mysql -h HOST -u USERNAME -p DBNAME
```

you can then run fault injection queries and observe the effect on the test script, e.g.:

```sql
ALTER SYSTEM CRASH NODE;
```
