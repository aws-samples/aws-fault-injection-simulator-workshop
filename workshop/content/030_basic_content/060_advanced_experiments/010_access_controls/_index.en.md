---
title: "Access controls"
weight: 10
services: false
draft: false
---

In the [**Configuring Permissions**]({{< ref "030_basic_content/030_basic_experiment/10-permissions" >}}) section we showed how to limit the access of a running FIS experiment. In this section we will demonstrate how to control user access to AWS Fault Injection Simulator (FIS). 

## Controlling user access to FIS

AWS Identity and Access Management (IAM) provides you fine-grained controls for to the use of FIS. As part of the provisioned infrastructure we have created three roles that can be assumed from within your account:

* `FisAccessControlAdmin` - This Role extends the `ReadOnlyAccess` AWS managed policy by adding all [**FIS actions**](https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsfaultinjectionsimulator.html#awsfaultinjectionsimulator-actions-as-permissions). Note that this role does not have permission to perform impacting actions outside of FIS such as terminating EC2 instances. Those permissions have to be granted by the FIS execution role. Navigate to the [**IAM Console**](https://console.aws.amazon.com/iam/home?#/roles/FisAccessControlAdmin) and expand the `AllowFisFullAccess` policy to see permissions granted.

* `FisAccessControlUser` - This Role extends the `ReadOnlyAccess` AWS managed policy by adding the ability to start/stop experiments and to tag Experiments (required to add the "Name" tag when starting an experiment). Note that this role does not have permission to perform impacting actions outside of FIS such as terminating EC2 instances. Those permissions have to be granted by the FIS execution role. Navigate to the [**IAM Console**](https://console.aws.amazon.com/iam/home?#/roles/FisAccessControlUser) and expand the `AllowFisUsageAccess` policy to see permissions granted.

* `FisAccessControlNonUser` - This Role extends the `ReadOnlyAccess` AWS managed policy by explicitly denying all FIS actions. Navigate to the [**IAM Console**](https://console.aws.amazon.com/iam/home?#/roles/FisAccessControlNonUser) and expand the `DenyFisAccess` policy to see permissions granted. 

### Exploring FIS with assumed roles

To see the effect of the above roles we will assume each role on the AWS console and explore its effect on the use of FIS.

{{% notice warning %}}
All tabs in a browser profile will share the same AWS identity. As such, assuming roles will expire all other active AWS console tabs and you will have to reload those tabs. Reloading the tabs will navigate to the same URL as before but with the new IAM Role .
{{% /notice %}}

#### Full access via FisAccessControlAdmin

To assume the `FisAccessControlAdmin` role navigate to the [**AWS console**](https://console.aws.amazon.com/console/home) and click on the user identity at the top to get an info drop down. From the drop-down copy the account ID (12 digit number). Finally select "Switch Roles".

{{< img "switch-role-1.png" "Switch role image" >}}

To define the role we would like to assume enter the account number you just copied and use the role name `FisAccessControlAdmin`. Pick a color to identify the role in the dropdown later. Since this is a privileged role we are using "red". Finally select "Switch Role".

{{< img "switch-role-2.png" "Switch role data entry" >}}

{{% notice note %}}
We will assume that you have previously created the `FisWorkshopExp1` Experiment template from the [**First Experiment**]({{< ref "030_basic_content/030_basic_experiment" >}}) section and will use that template for the examples below but this should work with other templates as well.
{{% /notice %}}

With the assumed role (visible at the top) navigate to the [**FIS console**](https://console.aws.amazon.com/fis/home?#ExperimentTemplates), select the `FisWorkshopExp1` template, and from the "Actions" drop down select "Start Experiment".

{{< img "start-exp-1.png" "Start experiment">}}

Add a new tag with "Key" `Name` and "Value" `FisAccessControlAdmin`, then select "Start Experiment" and confirm you wish to start the experiment.

{{< img "name-exp-1.png" "Name experiment">}}

Even though the `FisAccessControlAdmin` role itself does not have `ec2:TerminateInstances` privileges, the experiment will run and you will get a "Completed" or "Failed" result depending on how many instances were in the auto-scaling group, just as observed in the [**First Experiment**]({{< ref "030_basic_content/030_basic_experiment" >}}) section.

Just as in the First Experiment section you can also update the template as needed.

Before the next step, return to the normal workshop role by using the same dropdown you used to assume the role, then selecting "Back to ...". 

{{< img "return-role.png" "Return to workshop role">}}

#### Execution access via FisAccessControlUser

Repeat the assume role steps above with the `FisAccessControlUser` role. You may pick a different color, e.g. orange, to signify a less privileged user. 

With this role you can list experiments and experiment templates and run an experiment. However, this role is not allowed to edit an experiment template.

To test this, navigate to the [**FIS Console**](https://console.aws.amazon.com/fis/home?#ExperimentTemplates), select "Experiment Templates", select the `FisWorkshopExp1` template, and under the "Actions" drop down select "Update experiment template". 

{{< img "edit-template-user-1.png" "Edit template as user">}}

Edit the `FisWorkshopAsg-50Percent1` "Target", set "Selection mode" to `COUNT` and "Mumber of resources" to `1`, and select "Save" on the edit modal.

Select "Update experiment template" and confirm the intent to update. This will result in a failure banner informing you that the assumed role lacks the required edit/update privileges.

{{< img "edit-template-user-2.png" "Edit template as user failure">}}

Before the next step, return to the normal workshop role by using the same dropdown you used to assume the role, then selecting "Back to ...". 

#### No access via FisAccessControlNonUser

Repeat the assume role steps above with the `FisAccessControlNonUser` role. You may pick a different color, e.g. black, to signify an unprivileged user. 

Even though this role is based on the AWS managed `ReadOnlyAccess` policy, access to FIS has been explicitly denied. 

Navigate to the [**FIS Console**](https://console.aws.amazon.com/fis/home?#Home) and select "Experiment Templates". You will notice that no templates are listed because the user is not sufficiently privileged.

{{< img "non-user-templates.png" "Unprivileged list failure for templates">}}

Similarly if you select "Experiments" you will notice that no experiments are listed because the user is not sufficiently privileged.

{{< img "non-user-experiments.png" "Unprivileged list failure for experiments">}}
