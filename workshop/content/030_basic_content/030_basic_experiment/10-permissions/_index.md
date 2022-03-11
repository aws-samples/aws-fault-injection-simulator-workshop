---
title: "Configuring Permissions"
weight: 10
services: true
---

The AWS FIS security model uses two IAM roles. The first IAM role, the one you used to log into the console, controls access to AWS FIS service. It governs whether you are able to see, modify, and run AWS FIS experiments.

The second role governs what resources an AWS FIS experiment can affect during a fault injection experiment. For the purposes of this workshop, we will create one generic role. However, you can create fine grained IAM roles for each fault injection experiment.

### Create FIS service role

We need to create an [**IAM role for the AWS FIS service**](https://docs.aws.amazon.com/fis/latest/userguide/getting-started-iam.html#getting-started-iam-service-role) to grant it permissions to inject faults into the system. While we could have pre-created this IAM role for you, we think it is important to review its scope with you.

Navigate to the [**IAM console**](https://console.aws.amazon.com/iam/home?#/policies) and create a new IAM policy. On the "Create Policy" page select the **JSON** tab

{{< img "create-policy-1.en.png" "Create AWS FIS service policy" >}}

and paste the following policy. This policy is designed to allow you to freely test during the workshop but take the time to look at how broad these permissions are. We suggest limiting this policy using resource names and conditions before using FIS in production:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowFISExperimentLoggingActionsCloudwatch",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogDelivery",
                "logs:PutResourcePolicy",
                "logs:DescribeResourcePolicies",
                "logs:DescribeLogGroups"
            ],
            "Resource": "*"
        },
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

Click on **Next: Tags** to move to the next screen, adding any Tags as you'd wish. In the **Review Policy** page, save this policy as `FisWorkshopServicePolicy` and add any description you would like. Complete the policy creation by clicking on **Create Policy**.

Navigate to the [**IAM console**](https://console.aws.amazon.com/iam/home?#/roles) page and create a new **Role**.

On the "Select type of trusted entity" page AWS FIS does not exist as a trusted service yet. We shall add an account trust as a placeholder and replace this with AWS FIS later. Select **"Another AWS Account"** and add the current account number. You can find the AWS account number in the drop-down menu at the top right of the page as shown:

{{< img "create-role-1.en.png" "Create AWS FIS service role" >}}

Click on **Next: permissions**. On the "Attach permissions" page search for the `FisWorkshopServicePolicy` we just created and check the box beside it to attach it to the role.

{{< img "create-role-2.en.png" "Attach role policy" >}}

Click on **Next: Tags** and add any Tags you would like for this role.

Click on **Next: Review** and save the role name as `FisWorkshopServiceRole`. Add any description you would like for this role. 

Complete the Role creation by clicking on **Create role**.

Back in the **IAM Roles** page, find and edit the `FisWorkshopServiceRole`. Select **"Trust relationships"** and the **"Edit trust relationship"** button.

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

Click on **Update Trust Policy** to complete updating the Role.


