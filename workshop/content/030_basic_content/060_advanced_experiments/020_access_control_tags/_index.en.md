---
title: "Access control tags"
weight: 20
services: false
draft: false
---

In the previous section we saw how to use IAM roles and policies to control access to experiments and templates. In addition to fixed IAM policies it is also possible to use [**resource tags**](https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html) to add more granular access control. 

## Configuring CloudShell

{{% notice note %}}
To simplify the assume role functionality for the workshop, this section will use AWS CloudShell. If you want to use the same approach from other environments, [review this link](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-role.html) for other ways to configure your credentials provider.
{{% /notice %}}

{{% notice warning %}}
To protect your exisiting AWS CLI config file, we will use a custom AWS CLI config file. We will reference this file by setting the `AWS_CONFIG_FILE` environment variable. If you need to return to using your default config file either unset the environment variable or open a new CloudShell tab.
{{% /notice %}}

Navigate to [**CloudShell**](https://console.aws.amazon.com/cloudshell/home) and wait for your CloudShell instance to start up. 

Once ready, set up a directory in which to work and create a custom AWS CLI config file. This file defines profiles for the three roles we used in the previous secton plus an additional `FisAccessControlSecurityAdmin` role:

```
# Create same path as used by GitHub repository
mkdir -p ~/environment/aws-fault-injection-simulator-workshop/resources/templates/access-controls/
cd ~/environment/aws-fault-injection-simulator-workshop/resources/templates/access-controls/


ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account')
cat > aws_test_config <<EOT
[profile FisAccessControlSecurityAdmin]
    role_arn = arn:aws:iam::${ACCOUNT_ID}:role/FisAccessControlSecurityAdmin
    credential_source = EcsContainer

[profile FisAccessControlAdmin]
    role_arn = arn:aws:iam::${ACCOUNT_ID}:role/FisAccessControlAdmin
    credential_source = EcsContainer

[profile FisAccessControlUser]
    role_arn = arn:aws:iam::${ACCOUNT_ID}:role/FisAccessControlUser
    credential_source = EcsContainer

[profile FisAccessControlNonUser]
    role_arn = arn:aws:iam::${ACCOUNT_ID}:role/FisAccessControlNonUser
    credential_source = EcsContainer

EOT

export AWS_CONFIG_FILE=${PWD}/aws_test_config
export AWS_PAGER=""
```

Let's test the setup:

```
# Validate that we can assume the role
aws --profile FisAccessControlAdmin sts get-caller-identity

# List experiment templates
aws --profile FisAccessControlAdmin fis list-experiment-templates
```


## Restricting update permissions with tags

For this demonstration we will export the the first experiment template into two separate experiment templates files. In the first template file we will change the `Name` tag to `TagAccessTest1Dev` and add a new `Environment` tag with value `dev`. For the second template file we will change the `Name` tag to `TagAccessTest1Prod` and add a new `Environment` tag with value `prod`. Later in this section we will show how to use these tags for access control.

```
# Get experiment template ID
EXPERIMENT_TEMPLATE_ID=$( aws fis list-experiment-templates --query "experimentTemplates[?tags.Name=='FisWorkshopExp1'].id" --output text )

# Save template with a "dev" environment tag 
aws fis get-experiment-template --id $EXPERIMENT_TEMPLATE_ID \
| jq '.experimentTemplate' \
| jq 'del( .id) | del(.creationTime) | del(.lastUpdateTime)' \
| jq '.tags.Name="TagAccessTest1Dev"' \
| jq '.tags.Environment="dev"' \
> tag-test-template-dev.json

# Save template with a "prod" environment tag 
aws fis get-experiment-template --id $EXPERIMENT_TEMPLATE_ID \
| jq '.experimentTemplate' \
| jq 'del( .id) | del(.creationTime) | del(.lastUpdateTime)' \
| jq '.tags.Name="TagAccessTest1Prod"' \
| jq '.tags.Environment="prod"' \
> tag-test-template-prod.json
```

### Privileged user experience without prod constraint

Our newly created security admin user has no restrictions on their ability to use FIS. In particular this role is able to create experiment templates and experiments with any attached tags. 

As such it can create both the dev and prod experiment templates

```
# Privileged admin user can create dev templates
DEV_TEMPLATE_1=$(
  aws fis create-experiment-template \
    --profile FisAccessControlSecurityAdmin \
    --cli-input-json file://tag-test-template-dev.json \
    --query 'experimentTemplate.id' \
    --output text
)
echo $DEV_TEMPLATE_1

# Privileged admin user can create prod templates
PROD_TEMPLATE_1=$(
  aws fis create-experiment-template \
    --profile FisAccessControlSecurityAdmin \
    --cli-input-json file://tag-test-template-prod.json \
    --query 'experimentTemplate.id' \
    --output text
)
echo $PROD_TEMPLATE_1
```

It can start experiments from both dev and prod templates and can tag the resulting experiments with dev and prod tags

```
# Privileged admin can user start experiments from dev templates
DEV_EXPERIMENT_1=$(
  aws fis start-experiment \
    --profile FisAccessControlSecurityAdmin \
    --experiment-template-id ${DEV_TEMPLATE_1} \
    --tags \
        Name=FisWorkshop-TagLimit-Dev-FisAccessControlSecurityAdmin,Environment=dev \
    --query 'experiment.id' \
    --output text
)
echo $DEV_EXPERIMENT_1

# Privileged admin can user start and tag experiments from prod templates
PROD_EXPERIMENT_1=$(
  aws fis start-experiment \
    --profile FisAccessControlSecurityAdmin \
    --experiment-template-id ${PROD_TEMPLATE_1} \
    --tags \
        Name=FisWorkshop-TagLimit-Prod-FisAccessControlSecurityAdmin,Environment=prod \
    --query 'experiment.id' \
    --output text
)
echo $PROD_EXPERIMENT_1
```

It can retrieve the content of both dev and prod tagged experiment templates

```
# Privileged admin can retrieve dev experiment templates
aws fis get-experiment-template \
  --profile FisAccessControlSecurityAdmin \
  --id ${DEV_TEMPLATE_1}
  
# Privileged admin can retrieve prod experiment templates
aws fis get-experiment-template \
  --profile FisAccessControlSecurityAdmin \
  --id ${PROD_TEMPLATE_1}
```

It can retrieve the content of both dev and prod tagged experiments 

```
# Privileged admin can retrieve dev experiments
aws fis get-experiment \
  --profile FisAccessControlSecurityAdmin \
  --id ${DEV_EXPERIMENT_1}
  
# Privileged admin can retrieve prod experiments
aws fis get-experiment \
  --profile FisAccessControlSecurityAdmin \
  --id ${PROD_EXPERIMENT_1}
```

### Privileged user experience with prod constraint

Now lets look at a user that can perform any FIS actions _unless_ the resource created or used has an attached `Environment` tag with value `prod`.

Repeating the previous steps with the less privileged role / profile we can see that this user can create dev templates but cannot create templates with an attached `Environment` tag with value `prod`

```
# Admin user can create dev templates
DEV_TEMPLATE_2=$(
  aws fis create-experiment-template \
    --profile FisAccessControlAdmin \
    --cli-input-json file://tag-test-template-dev.json \
    --query 'experimentTemplate.id' \
    --output text
)
echo $DEV_TEMPLATE_2

# Admin user cannot create prod templates
PROD_TEMPLATE_2=$(
  aws fis create-experiment-template \
    --profile FisAccessControlAdmin \
    --cli-input-json file://tag-test-template-prod.json \
    --query 'experimentTemplate.id' \
    --output text
)
echo $PROD_TEMPLATE_2
```

The constrained admin role can start experiments from templates tagged with an `Environment` tag with value `dev` but not with value `prod`. The constrained role also cannot start experiments from `dev` templates and tag the result as `prod`.

```
# Admin can user start experiments from dev templates
DEV_EXPERIMENT_2=$(
  aws fis start-experiment \
    --profile FisAccessControlAdmin \
    --experiment-template-id ${DEV_TEMPLATE_1} \
    --tags \
        Name=FisWorkshop-TagLimit-Dev-FisAccessControlAdmin,Environment=dev \
    --query 'experiment.id' \
    --output text
)
echo $DEV_EXPERIMENT_2

# Admin cannot user start experiments from prod templates
DEV_EXPERIMENT_3=$(
  aws fis start-experiment \
    --profile FisAccessControlAdmin \
    --experiment-template-id ${PROD_TEMPLATE_1} \
    --tags \
        Name=FisWorkshop-TagLimit-Dev-FisAccessControlAdmin,Environment=dev \
    --query 'experiment.id' \
    --output text
)
echo $DEV_EXPERIMENT_3

# Admin cannot user tag experiments with prod tag
PROD_EXPERIMENT_2=$(
  aws fis start-experiment \
    --profile FisAccessControlAdmin \
    --experiment-template-id ${DEV_TEMPLATE_1} \
    --tags \
        Name=FisWorkshop-TagLimit-Prod-FisAccessControlAdmin,Environment=prod \
    --query 'experiment.id' \
    --output text
)
echo $PROD_EXPERIMENT_2
```

The constrained role can retrieve the content of experiment templates with an attached `Environment` tag with value `dev` but not `prod`

```
# Admin can retrieve dev experiment templates
aws fis get-experiment-template \
  --profile FisAccessControlAdmin \
  --id ${DEV_TEMPLATE_1}
  
# Admin can retrieve prod experiment templates
aws fis get-experiment-template \
  --profile FisAccessControlAdmin \
  --id ${PROD_TEMPLATE_1}
```

The constrained role can retrieve the content of experiments with an attached `Environment` tag with value `dev` but not `prod`

```
# Admin can retrieve dev experiments
aws fis get-experiment \
  --profile FisAccessControlAdmin \
  --id ${DEV_EXPERIMENT_1}
  
# Admin can retrieve prod experiments
aws fis get-experiment \
  --profile FisAccessControlAdmin \
  --id ${PROD_EXPERIMENT_1}
```

Note that list operations are not constrained by tags so this user can still see the list of all prod experiments that have been performed.

### Unprivileged user experience

Repeating the above commands with the `FisAccessControlUser` role will demonstrate the additional constraint of not being able to create experiment templates. Like the constrained admin user, this user can see the list of all prod experiments that have been performed.

Repeating the above commands with the `FisAccessControlNonUser` will show no access to FIS resources. Because this role's access to FIS has been constrained by an explicit deny it also cannot list experiment templates or experiments even though the AWS managed `ReadOnlyAccess` policy would have allowed the list actions.


