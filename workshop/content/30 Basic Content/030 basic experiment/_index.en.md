+++
title = "First Experiment"
date =  2021-04-14T17:25:17-06:00
weight = 3
+++

In the previous section we saw how

* hypothesis: with ASG killing off an instance under normal load will not negatively affect users

* do not scale up

## Create FIS service role

We need to create a [role for the FIS service](https://docs.aws.amazon.com/fis/latest/userguide/getting-started-iam.html#getting-started-iam-service-role) to grant it permissions to inject chaos. While we could have pre-created this role for you we think it is important to review the scope of this role.

Navigate to the [IAM console](https://console.aws.amazon.com/iam/home?#/policies) and create a new policy called `FisWorkshopServicePolicy`. On the *Create Policy* page select the JSON tab

{{< img "create-policy-1.en.png" "Create FIS service role" >}}

and paste the following policy - take the time to look at how broad these permissions are:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowFISExperimentRoleReadOnly",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ecs:DescribeClusters",
                "ecs:ListContainerInstances",
                "eks:DescribeNodegroup",
                "iam:ListRoles",
                "rds:DescribeDBInstances",
                "rds:DescribeDbClusters",
                "ssm:ListCommands"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowFISExperimentRoleEC2Actions",
            "Effect": "Allow",
            "Action": [
                "ec2:RebootInstances",
                "ec2:StopInstances",
                "ec2:StartInstances",
                "ec2:TerminateInstances"
            ],
            "Resource": "arn:aws:ec2:*:*:instance/*"
        },
        {
            "Sid": "AllowFISExperimentRoleECSActions",
            "Effect": "Allow",
            "Action": [
                "ecs:UpdateContainerInstancesState",
                "ecs:ListContainerInstances"
            ],
            "Resource": "arn:aws:ecs:*:*:container-instance/*"
        },
        {
            "Sid": "AllowFISExperimentRoleEKSActions",
            "Effect": "Allow",
            "Action": [
                "ec2:TerminateInstances"
            ],
            "Resource": "arn:aws:ec2:*:*:instance/*"
        },
        {
            "Sid": "AllowFISExperimentRoleFISActions",
            "Effect": "Allow",
            "Action": [
                "fis:InjectApiInternalError",
                "fis:InjectApiThrottleError",
                "fis:InjectApiUnavailableError"
            ],
            "Resource": "arn:*:fis:*:*:experiment/*"
        },
        {
            "Sid": "AllowFISExperimentRoleRDSReboot",
            "Effect": "Allow",
            "Action": [
                "rds:RebootDBInstance"
            ],
            "Resource": "arn:aws:rds:*:*:db:*"
        },
        {
            "Sid": "AllowFISExperimentRoleRDSFailOver",
            "Effect": "Allow",
            "Action": [
                "rds:FailoverDBCluster"
            ],
            "Resource": "arn:aws:rds:*:*:cluster:*"
        },
        {
            "Sid": "AllowFISExperimentRoleSSMSendCommand",
            "Effect": "Allow",
            "Action": [
                "ssm:SendCommand"
            ],
            "Resource": [
                "arn:aws:ec2:*:*:instance/*",
                "arn:aws:ssm:*:*:document/*"
            ]
        },
        {
            "Sid": "AllowFISExperimentRoleSSMCancelCommand",
            "Effect": "Allow",
            "Action": [
                "ssm:CancelCommand"
            ],
            "Resource": "*"
        }
    ]
}
```

Navigate to the [IAM console](https://console.aws.amazon.com/iam/home?#/roles) and create a new role called `FisWorkshopServiceRole`.

On the *Select type of trusted entity* page FIS does not exist as a trusted service so select "Another AWS Account" and add the current account number. You can find the account number in the drop-down menu as shown:

{{< img "create-role-1.en.png" "Create FIS service role" >}}

On the *Attach permissions* page search for the `FisWorkshopServicePolicy` we just created and check the box beside it to attach it to the role.

{{< img "create-role-2.en.png" "Create FIS service role" >}}

Back in the IAM roles console, find and edit the `FisWorkshopServiceRole`. Select *Trust relationsips* and the *Edit trust relationship* button.

{{< img "create-role-3.en.png" "Create FIS service role" >}}

Replace the policy document with the following:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": [
                  "fis.amazonaws.com"
                ]
            },
            "Action": "sts:AssumeRole",
            "Condition": {}
        }
    ]
}
```


## Create FIS experiment template

To run an experiment we need to first create a template _defining_ the [Actions](https://docs.aws.amazon.com/fis/latest/userguide/actions.html), [Targets](https://docs.aws.amazon.com/fis/latest/userguide/targets.html), and optionally [Stop Conditions](https://docs.aws.amazon.com/fis/latest/userguide/stop-conditions.html).  

Navigate to the [FIS console](https://console.aws.amazon.com/fis/home?#Home) and select "Create experiment template".

{{< img "create-template-1.en.png" "Create FIS experiment template" >}}

{{% notice note %}}
Note: if you've used FIS before you may not see the splash screen. In that case select "Experiment templates" in the menu on the left and access "Create experiment template" from there.
{{% /notice %}}

For our first experiment we will jump around in the definition page so follow closely.

### Template name

First, let's give our template a short name to be used on the list page. To do this scroll to the "Tags" section at the bottom, select "Add new tag", then enter `Name` in the "Key" field and `FisWorkshopExp1` for "Value"

{{< img "create-template-2-name.en.png" "Set FIS template name" >}}

### Template description and permissions

Next let's set description and role for the first run of the experiment. Scroll back to the "Description and permission" section at the top. For "Description" enter `Terminate half of the instances in the autoscaling group` and for "Role" select the `FisWorkshopServiceRole` role you created above.

{{< img "create-template-2-description.en.png" "Set FIS description and role" >}}

### Target selection

Now we need to define targets. For our first experiment we will start with the hypothesis that due to our auto-scaling setup we can safely impact half the instances in our autoscaling group. Scroll to the "Targets" section and select "Add Target"

{{< img "create-template-2-targets-1.en.png" "Add FIS target" >}}

On the "Add target" popup enter `FisWorkshopAsg-50Percent` for name and select `aws:ec2:instances`. For "Target method" we will dynamically select resources based on an associated tag. Select the `Resource tags and filters` checkbox. Pick `Percent` from "Selection mode" and enter `50`. Under "Resource tags" enter `Name` in the "Key" field and `fis-asg-server` for "Value". We will not be using filters for the first experiment. Select "Save".

{{< img "create-template-2-targets-2.en.png" "Add FIS target" >}}

### Action definition

With targets defined we define the action to take. To test the hypothesis that we can safely impact half the instances in our autoscaling group we will terminate those instances. Scroll to the "Actions" section" and select "Add Action"

{{< img "create-template-2-actions-1.en.png" "Add FIS actions" >}}

For "Name" enter `FisWorkshopAsg-TerminateInstances` and add a "Description" like `Terminate instances`. For "Action type" select `aws:ec2:terminate-instances`.

We will leave the "Start after" section blank since the instances we are terminating are part of an autoscaling group and we can let the autoscaling group create new instances to replace the terminated ones.

Under "Target" select the `FisWorkshopAsg-50Percent` target created above. Select "Save".

{{< img "create-template-2-actions-2.en.png" "Add FIS actions" >}}

### Creating template without stop conditions

Scroll to the bottom of the template definition page and select "Create experiment template". Since we didn't specify a stop condition we receive a warning:

{{< img "create-template-2-actions-1.en.png" "Add FIS actions" >}}

This is ok, for this experiment we don't need a stop condition. Type `create` in the text box as indicated and select "Create experiment template".

{{< img "create-template-3-confirm.en.png" "Save FIS template" >}}

## Run FIS experiment

As previously discussed, we should collect both customer and ops metrics. In future sections we will show you how you could build the load generator into your experiment.

For this experiment we will manually generate some load on the system before starting the experiment similar to what we did in the previous section. Here we have increased the run time to 5 minutes by setting `ExperimentDurationSeconds` to 300:

```bash
# Please ensure that LAMBDA_ARN and URL_HOME are still set from previous section
aws lambda invoke \
  --function-name ${LAMBDA_ARN} \
  --payload "{
        \"ConnectionTargetUrl\": \"${URL_HOME}\",
        \"ExperimentDurationSeconds\": 300,
        \"ConnectionsPerSecond\": 1000,
        \"ReportingMilliseconds\": 1000,
        \"ConnectionTimeoutMilliseconds\": 2000,
        \"TlsTimeoutMilliseconds\": 2000,
        \"TotalTimeoutMilliseconds\": 2000
    }" \
  --invocation-type Event \
  invoke.txt
```

To start the experiment navigate to the [FIS console](https://console.aws.amazon.com/fis/home?#ExperimentTemplates), select the `FisWorkshopExp1` template we just created.  Under "Actions" select "Start experiment".

{{< img "start-experiment-1.en.png" "Start experiment add tags" >}}

Let's give the experiment run a friendly name for finding it later on the list page. Under "Experiment tags" enter `Name` for "Key and `FisWorkshopExp1Run1`then select "Start experiment".

{{< img "start-experiment-2.en.png" "Start experiment confirmation" >}}

Because you are about to start a potentially destructive process you will be asked to confirm that you really want to do this. Type `start` as directed and select "Start experiment".

{{< img "start-experiment-3.en.png" "Start experiment" >}}

## Review results

If you are not already on the pane viewing your experiment, navigate to the [FIS console](https://console.aws.amazon.com/fis/home?#Experiments), select "Experiments", and select the experiment ID for the experiment you just started.

Look at the "State" entry. If this still shows pending, feel free to select the "Refresh" button a few times until you see a result. If you followed the above steps carefully there is a good chance that your experiment state will be "Failed".

{{< img "run-experiment-1-fail.en.png" "Start experiment confirmation" >}}

Click on the failed result to get more information about why it failed. The message should say "Target resolution returned empty set". To see why this would happen, have a look at the autoscaling group from which we tried to select instances. Navigate to the [EC2 console](https://console.aws.amazon.com/ec2autoscaling/home?#/details), select "Auto Scaling Groups" on the bottom of the left menu, and search for "FisStackAsg-WebServerGroup":

{{< img "review-1-asg-1.en.png" "Review ASG" >}}

It looks like our ASG was configured to scale down to just one instance while idle. Since we can't shut down half of one instance our 50% selector came up empty and the experiment failed.

**Great! While this wasn't really what we expected, we just found a flaw in our configuration that would severely affect resilience! Let's fix it and try again!**

Click on the autoscaling group name and "Edit" the "Group Details" to raise both the "Desired capacity" and "Minimum capacity" to `2`.

{{< img "review-1-asg-2.en.png" "Update ASG" >}}

Check the ASG details or the CloudWatch Dashboard we explored in the previous section to make sure the active instances count has come up to 2.

To repeat the experiment, repeat the steps above:

* restart the load
* navigate back to the [FIS Experiment Templates Console](https://console.aws.amazon.com/fis/home?#ExperimentTemplates), start the experiment adding a `Name` tag of `FisWorkshopExp1Run2`
* check to make sure the experiment succeeded

Finally navigate to the [CloudWatch Dashboard](https://console.aws.amazon.com/cloudwatch/home?#dashboards:) from the previous section. Review the number of instances in the ASG going down and then up again and review the error responses reported by the load test.

## Findings and next steps

From this experiment we learned:

* Carefully choose the resource to affect and how to select them. If we had originally chosen to terminate a single instance (COUNT) rather than a fraction (PERCENT) we would have severely affected our service.
* Spinning up instances takes time. To achieve resilience ASGs should be set to have at least two instances running at all times

In the next section we will explore larger experiments.

{{%expand "TODO: Athena queries - probably on different page" %}}
TODO - move athena view of events onto an appropriate page

```sql
SELECT *
FROM cloudtrail_logs_aws_cloudtrail_logs_238810465798_e649b22c
WHERE sourceipaddress = 'fis.amazonaws.com' limit 10

WHERE eventname = 'TerminateInstances' limit 10

SELECT json_extract(responseelements, '$.instancesSet.items')

-- What did FIS do
SELECT cast(eventtime as varchar),eventname,*
FROM cloudtrail_logs_aws_cloudtrail_logs_238810465798_e649b22c
WHERE useridentity.invokedby = 'fis.amazonaws.com' order by eventtime

-- tie stuff to an event ...
SELECT cast(eventtime as varchar),eventname,*
FROM cloudtrail_logs_aws_cloudtrail_logs_238810465798_e649b22c
WHERE
    useragent = 'fis.amazonaws.com' and
    (
        useridentity.principalId LIKE '%EXPLAMUGrokQJrV4hw%' OR
        requestparameters LIKE '%EXPLAMUGrokQJrV4hw%' OR
        responseelements LIKE '%EXPLAMUGrokQJrV4hw%'
    )
order by eventtime

-- Comment
WITH
    c AS
        (SELECT
            concat('%','EXPLAMUGrokQJrV4hw','%') AS experimentId ),
    v AS
        (SELECT
            cast(eventtime AS varchar) timestamp,
            eventname AS evn,
            *
        FROM cloudtrail_logs_aws_cloudtrail_logs_238810465798_e649b22c
        WHERE useridentity.invokedby = 'fis.amazonaws.com' )
SELECT
    v.timestamp,
    v.eventname,
    c.experimentId,
    *
FROM v LEFT JOIN c ON 1=1
WHERE
    useridentity.principalId LIKE experimentId OR
    requestparameters        LIKE experimentId OR
    responseelements         LIKE experimentId
ORDER BY
    v.timestamp


-- just instances
WITH
    c AS
        (SELECT
            concat('%','EXPLAMUGrokQJrV4hw','%') AS experimentId ),
    v AS
        (SELECT
            cast(eventtime AS varchar) as timestamp,
            *
        FROM cloudtrail_logs_aws_cloudtrail_logs_238810465798_e649b22c
        WHERE useridentity.invokedby = 'fis.amazonaws.com' )
SELECT
    v.timestamp,
    v.eventname,
    json_extract(v.requestparameters,'$.instancesSet.items') as instance
FROM v LEFT JOIN c ON 1=1
WHERE
    useridentity.principalId LIKE experimentId OR
    requestparameters        LIKE experimentId OR
    responseelements         LIKE experimentId
ORDER BY
    v.timestamp    
```

```bash
  --work-group 'primary' \
export EXPERIMENT_ID="EXPLAMUGrokQJrV4hw"
export CLOUD_TRAIL="cloudtrail_logs_aws_cloudtrail_logs_238810465798_e649b22c"
export OUTPUT_LOCATION="s3://aws-cloudtrail-logs-238810465798-e649b22c/query-results/"
aws athena start-query-execution \
  --result-configuration "OutputLocation=${OUTPUT_LOCATION}" \
  --query-string "
WITH
    c AS
        (SELECT
            concat('%','${EXPERIMENT_ID}','%') AS experimentId ),
    v AS
        (SELECT
            cast(eventtime AS varchar) as timestamp,
            *
        FROM ${CLOUD_TRAIL}
        WHERE useridentity.invokedby = 'fis.amazonaws.com' )
SELECT
    v.timestamp,
    v.eventname,
    json_extract(v.requestparameters,'\$.instancesSet.items') as instance
FROM v LEFT JOIN c ON 1=1
WHERE
    useridentity.principalId LIKE experimentId OR
    requestparameters        LIKE experimentId OR
    responseelements         LIKE experimentId
ORDER BY
    v.timestamp    
" \
| tee query_execution_id.json

export LAST_QUERY_ID=$( jq -rc .QueryExecutionId query_execution_id.json )

aws athena get-query-results --query-execution-id ${LAST_QUERY_ID} \
| tee query_results.json

jq -c '.ResultSet.Rows[].Data | [ .[0].VarCharValue, .[1].VarCharValue, .[2].VarCharValue // "" ] ' query_results.json
```

```bash
  --work-group 'primary' \
export EXPERIMENT_ID="EXPLAMUGrokQJrV4hw"
export EXPERIMENT_ID="EXPYbnYRHvgU6bHc5o"
export CLOUD_TRAIL="cloudtrail_logs_aws_cloudtrail_logs_238810465798_e649b22c"
export OUTPUT_LOCATION="s3://aws-cloudtrail-logs-238810465798-e649b22c/query-results/"
export EXPERIMENT_QUERY_STRING="%${EXPERIMENT_ID}%"
aws athena start-query-execution \
  --result-configuration "OutputLocation=${OUTPUT_LOCATION}" \
  --query-string "
SELECT
    cast(eventtime AS varchar) as timestamp,
    eventname,
    json_extract(requestparameters,'\$.instancesSet.items') as instance
FROM ${CLOUD_TRAIL}
WHERE
    useridentity.invokedby = 'fis.amazonaws.com' AND (
        useridentity.principalId LIKE '${EXPERIMENT_QUERY_STRING}' OR
        requestparameters        LIKE '${EXPERIMENT_QUERY_STRING}' OR
        responseelements         LIKE '${EXPERIMENT_QUERY_STRING}'
    )
ORDER BY
    timestamp    
" \
| tee query_execution_id.json

export LAST_QUERY_ID=$( jq -rc .QueryExecutionId query_execution_id.json )

aws athena get-query-results --query-execution-id ${LAST_QUERY_ID} \
| tee query_results.json

jq -c '.ResultSet.Rows[].Data | [ .[0].VarCharValue, .[1].VarCharValue, .[2].VarCharValue // "" ] ' query_results.json
```

```bash
# Get the template that we manually created
aws fis get-experiment-template --id EXT5KVPKSbd2fEr5n
```

{{% /expand %}}
