---
title: "Aurora Cluster Failover"
weight: 20
services: true
---

## Experiment idea

In the previous section we ensured that we have a resilient front end of servers in an Auto Scaling group. Typically these servers would depend on a resilient database configuration. Let's validate this:

* **Given**: we have a managed database with a replica and automatic failover enabled
* **Hypothesis**: failure of a single database instance / replica may slow down a few requests but will not adversely affect our application

## Experiment setup

{{% notice note %}}
We are assuming that you know how to set up a basic FIS experiment and will focus on things specific to this experiment. If you need a refresher see the previous [**First Experiment**]({{< ref "030_basic_content/030_basic_experiment/" >}}) section.
{{% /notice %}}

### General template setup

* Create a new experiment template
  * Add `Name` tag of `FisWorkshopAurora1`
  * Add `Description` of `FailoverAuroraCluster`
  * Select `FisWorkshopServiceRole` as execution role

### Action definition

In the “Actions” section select the **“Add Action”** button.

For "Name" enter `FisWorkshopFailoverAuroraCluster` and add a "Description" like `Failover Aurora Cluster`. For "Action type" select `aws:rds:failover-db-cluster`.

Leave the default “Target” `Clusters-Target-1` and select **“Save”**.

{{< img "create-template-2-actions-2-rev1.en.png" "Edit FIS actions" >}}

### Target selection

For this action we need to select our Amazon Aurora "Cluster". For this we will need to know the instance resource ID. To find this ID open a new browser window and navigate to the [**RDS console**](https://console.aws.amazon.com/rds/home?#databases:)). Note the "DB identifier" for the target cluster, the one with "Engine" type "Aurora MySQL" and "Role" "Regional Cluster".

{{< img "rds-check-resource-id.en.png" "Edit FIS target" >}}

Return to the FIS experiment setup, scroll to the "Targets" section, select `Clusters-Target-1` and select **"Edit"**.

You may leave the default name `Clusters-Target-1` but for maintainability we rcommend using descriptive target names. Change "Name" to `FisWorkshopAuroraCluster` for name (this will automatically update the name in the action as well) and make sure "Resource type" is set to `aws:rds:cluster`. 

For "Target method" we will select resources based on the ID. Select the "Resource IDs" checkbox. Under "Resource IDs" pick the target DB instance matching the "DB Identifier" you noted above, then select `All` from "Selection mode". Select **"Save"**.

{{< img "create-template-2-targets-2-rev1.en.png" "Edit FIS target" >}}

### Creating template without stop conditions

Select **“Create experiment template”** and confirm that you wish to create a template without stop conditions.

## Validation procedure

The validation procedure is identical to what we did in the [**RDS DB Instance Reboot**]({{< ref "030_basic_content/050_databases/010_rds_database_reboot" >}}) section. If you have not explored that section before, perform the steps as described there under the "Validation Procedure" heading and return here when you reach the "Run FIS experiment" heading.

## Run FIS experiment

{{% notice note %}}
We are assuming that you know how to set up a basic FIS experiment and will focus on things specific to this experiment. If you need a refresher see the previous [**First Experiment**]({{< ref "030_basic_content/030_basic_experiment/" >}}) section.
{{% /notice %}}

### Record current Aurora state

Navigate to the [**RDS console**](https://console.aws.amazon.com/rds/home), select **"Databases"** on the left menu, and search for "fisworkshop". Take a screenshot or write down the "Reader" and "Writer" AZ information, e.g.:

{{< img "review-1-rds-1.en.png" "Explore aurora initial state" >}}

### Start the experiment

* Select the `FisWorkshopAurora1` experiment template you created above 
* Select start experiment
* Add a `Name` tag of `FisWorkshopAurora1Run1`
* Confirm that you want to start an experiment
* Watch the output of your test script 

### Review results

Verify that the experiment worked. If you are not already on the pane viewing your experiment, navigate to the [**FIS console**](https://console.aws.amazon.com/fis/home?#Experiments), select **"Experiments"**, and select the experiment ID for the experiment you just started. This should show "success".

Verify that the failover actually happened. Navigate to the RDS console again and about a minute after you started the experiment you'll see the "Reader" and "Writer" instances flipped to the other AZ:

{{< img "review-1-rds-2.en.png" "Explore aurora changed state" >}}

If all went well, the "Reader" and "Writer" instances should have traded places. 

If you were watching the output of your test script carefully you might also have noticed that for a short period of time DNS returns no value for Aurora. To address this our code already contains an additional try/except block for DB reconnection (see [**code in GitHub**](https://github.com/aws-samples/aws-fault-injection-simulator-workshop/blob/main/resources/templates/asg-cdk/assets/test_pymysql_curses.py#L88-L92)).


## Learning and improving

As this was essentially the same as the previous [**RDS DB Instance Reboot**]({{< ref "030_basic_content/050_databases/010_rds_database_reboot" >}}) section there are no new learnings here.

However, you may want to experiment further with built-in Aurora fault injenction queries for  [**MySQL**](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraMySQL.Managing.FaultInjectionQueries.html) and [**PostgreSQL**](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Managing.FaultInjectionQueries.html).

E.g. for the Aurora MySQL database provisioned in this workshop, you can extract the connection information from the [**AWS Secrets Manager console**](https://console.aws.amazon.com/secretsmanager/home?#!/secret?name=FisAuroraSecret) by selecting the `FisAuroraSecret` and selecting **"Retrieve secret value"**:

{{< img "ssm-get-secret.en.png" "Retrieve database credentials from Secrets Manager" >}}

Using the information you can open another terminal, e.g. from the same instance you were using for testing, and connect to your Aurora database with the retrieved secret values:

{{% expand "Expand to see scripted version" %}}

```bash
# Query Secret ARN and JSON content for convenience
export DB_MYSQL_SECRET_ARN=$( aws cloudformation describe-stacks --stack-name FisStackRdsAurora --query "Stacks[*].Outputs[?OutputKey=='FisMysqlSecret'].OutputValue" --output text )
export DB_MYSQL_SECRET_JSON=$( aws secretsmanager get-secret-value --secret-id ${DB_MYSQL_SECRET_ARN} --output json )

# hostname  / username / dbname from secret
export DB_HOST_NAME=$( echo $DB_MYSQL_SECRET_JSON | jq -rc '.SecretString | fromjson | .host' )
export DB_USER_NAME=$( echo $DB_MYSQL_SECRET_JSON | jq -rc '.SecretString | fromjson | .username' )
export DB_NAME=$( echo $DB_MYSQL_SECRET_JSON | jq -rc '.SecretString | fromjson | .dbname' )

# Because now you might not have looked at the secret
echo Password $( echo $DB_MYSQL_SECRET_JSON | jq -rc '.SecretString | fromjson | .password' )
```
{{% /expand %}}

```bash
# hostname  / username / dbname from secret
export DB_HOST_NAME=[host from secret]
export DB_USER_NAME=[username from secret]
export DB_NAME=[dbname from secret]
```

{{% notice note %}}
The code below will not work from CloudShell because the database is in a private VPC. Make sure to run this from an EC2 instances with access to the VPC"
{{% /notice %}}

```bash
mysql -h $DB_HOST_NAME -u $DB_USER_NAME -p $DB_NAME
```

you can then run fault injection queries as further explained in this [**blog post**](https://aws.amazon.com/blogs/architecture/perform-chaos-testing-on-your-amazon-aurora-cluster/) and observe the effect on the test script, e.g.:

```sql
ALTER SYSTEM CRASH NODE;
```

Note that in contrast to the FIS actions these actions will only affect the connection making the queries. All other connections to the database will be unaffected by this simulation.
