---
title: "Template sharing"
weight: 40
services: false
draft: false
---

AWS Fault Injection Simulator is a regional service that allows targeting resources by availability zones or even affect all resources in a region to simulate whole region outages.

However, there are two scenarios where you might want to manage experiment templates across multiple regions and multiple accounts:

* **Users from one account accessing FIS in another account**, e.g. because you are using a [**multi-account strategy**](https://docs.aws.amazon.com/controltower/latest/userguide/aws-multi-account-landing-zone.html)
* **Template replication**, e.g. because you are running identical stacks in multiple regions and want to run identical experiments in all regions

## Cross-account access

{{% notice warning %}}
This workshop only provisions _one_ account. If you wish to test this you will need _another_ account. If you use one of your corporate accounts to test this as part of the workshop please make sure that (1) your corporate account is the one _assuming_ the role ("client") and (2) you remove any role changes you've made in your corporate ("client") account to access the workshop ("server") account.
{{% /notice %}}

We will assume that you have a firm grasp of the assume role procedure from the [**Access controls**]({{< ref "030_basic_content/060_advanced_experiments/010_access_controls" >}}) section. If not we suggest you revisit that section and consult the [**AWS documentation**](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-console.html).

### Enabling access from the workshop "server" account

Follow these steps

* Note the account ID for your workshop account - we will refer to this as `111122223333` or "server" for the remainder of this section. 
* Note the account ID for your other account - we will refer to this as `444455556666` or "client" for the remainder of this section.
* In your "server" account navigate to the [**IAM console**](https://console.aws.amazon.com/iam/home#/roles/FisAccessControlSecurityAdmin?section=trust) and locate the `FisAccessControlSecurityAdmin` role.
* Select the role and select the "Trust relationships" tab. This tab should currently show a single entry under "Trusted entities", the "server" account `111122223333`
* Select "Edit trust relationship"
* Update the JSON to read (replace the account IDs appropriately):
  ```
  {
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "AWS": [
            "arn:aws:iam::111122223333:root",
            "arn:aws:iam::444455556666:root"
            ]
        },
        "Action": "sts:AssumeRole"
        }
    ]
  }
  ```
* Select "Update Trust Policy"

### Accessing from the client account

{{% notice warning %}}
All tabs in a browser profile will share the same AWS identity. As such, logging into another AWS account or assuming roles will expire all other active AWS console tabs and you will have to reload those tabs. For this section we suggest that you use an browser profiles ([**Chrome**](https://support.google.com/chrome/answer/2364824?hl=en&co=GENIE.Platform%3DDesktop), [**Firefox**](https://support.mozilla.org/en-US/kb/profile-manager-create-remove-switch-firefox-profiles)) or use an incognito window to avoid confusion about which account you are logged into.
{{% /notice %}}

In a new browser / profile / incognito window log into your "client" AWS account, which should be distinct from your workshop account.

In the "client" account window follow the same procedure outlined in the [**Access controls**]({{< ref "030_basic_content/060_advanced_experiments/010_access_controls" >}}) section. For "Account" enter the workshop / "server" account number `111122223333`. For "Role" enter the name (not the ARN) of the role you want to assume, in this case the role that we modified above to allow access: e.g. `FisAccessControlSecurityAdmin`. Pick a color, we suggest blue to differentiate it from the other choices in this workshop, and select "Switch Role".

At this point you should see a blue indicator at the top of your console indicating that you are no longer "client" account `444455556666` but are instead logged into the "server" account `111122223333` with role `FisAccessControlSecurityAdmin`. You should also be able to see your role history in the left part of the drop down indicating your origin "client" account and role.

{{< img "cross-account-assumed-1.png" "Cross account role assumed" >}}

As this approach is based on IAM you can use instance or service roles in the "client" account or you can configure the AWS CLI to use [**profiles that assume a role**](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-role.html) or to [**use AWS SSO**](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html). 

## Template replication

Currently templates are static objects and in many cases need to reference targeted resources with account and region specific information. We have previously covered how to [**create templates**]({{< ref "030_basic_content/030_basic_experiment" >}}) via CLI or CloudFormation and we have discussed access controls earlier in this section so we will limit the discussion to a few points for you to consider:

* **ARNs** - where ARNs are required, e.g. execution roles, ECS or EKS clusters, and SSM documents, these must contain the account number. If you use CloudFormation you can inject this information using [**Pseudo Parameters**](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html#cfn-pseudo-param-accountid). If you prefer using a CLI/API approach you can use a JSON templating engine such as [**mustache**](http://mustache.github.io/) or [**handlebars**](https://handlebarsjs.com/). 
* **Static resources** - while FIS allows targeting resources based on filters, sometimes it is necessary to specify a particular resource via ID or ARN. If you use CloudFormation and can define the FIS experiment template in the same CloudFormation template as the resource then you can directly reference the resource. If you opt for a CLI/API approach, most JSON templating engines allow injecting variables so you could write a small script to do the lookup in the target account and parametrize your template. 
* **AZ naming** - if you need to replicate templates across accounts but wish to perform an experiment that targets the same AZ across multiple accounts you will need to determine the correct [**AZ ID**](https://docs.aws.amazon.com/ram/latest/userguide/working-with-az-ids.html) as part of the templating.

## Managing infrastructure across multiple accounts

In addition to sharing templates across accounts you will need to manage IAM roles, SSM documents, and other resources across accounts to ensure consistency in naming, access controls, etc. While there are many ways to achieve this we recommend reviewing [**AWS CloudFormation StackSets**](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/what-is-cfnstacksets.html), 
