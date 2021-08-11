+++
title = "Configuring Permissions"
weight = 10
+++

The FIS security model uses two roles. The first role, the one you used to log into the console, controls access to FIS. It governs whether you are able to see, modify, and run FIS experiments.

The second role governs what resources an FIS experiment can affect during execution. For the purposes of this workshop we will create one generic role but you can create fine grained roles for each experiment type.

### Create FIS service role

We need to create a [role for the FIS service](https://docs.aws.amazon.com/fis/latest/userguide/getting-started-iam.html#getting-started-iam-service-role) to grant it permissions to inject chaos. While we could have pre-created this role for you we think it is important to review the scope of this role.

Navigate to the [IAM console](https://console.aws.amazon.com/iam/home?#/policies) and create a new policy called `FisWorkshopServicePolicy`. On the *Create Policy* page select the JSON tab

{{< img "create-policy-1.en.png" "Create FIS service policy" >}}

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

On the **Select type of trusted entity** page FIS does not exist as a trusted service so select "Another AWS Account" and add the current account number. You can find the account number in the drop-down menu as shown:

{{< img "create-role-1.en.png" "Create FIS service role" >}}

On the **Attach permissions** page search for the `FisWorkshopServicePolicy` we just created and check the box beside it to attach it to the role.

{{< img "create-role-2.en.png" "Attach role policy" >}}

Back in the **IAM Roles** page, find and edit the `FisWorkshopServiceRole`. Select *Trust relationships* and the *Edit trust relationship* button.

{{< img "create-role-3.en.png" "Edit trust relationship" >}}

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






