+++
title = "RDS DB Instance Reboot"
weight = 4
+++



## Create FIS experiment template

To run an experiment we need to first create a template _defining_ the [Actions](https://docs.aws.amazon.com/fis/latest/userguide/actions.html), [Targets](https://docs.aws.amazon.com/fis/latest/userguide/targets.html), and optionally [Stop Conditions](https://docs.aws.amazon.com/fis/latest/userguide/stop-conditions.html).  

Navigate to the [FIS console](https://console.aws.amazon.com/fis/home?#Home) and select "Create experiment template".

{{< img "create-template-1.en.png" "Create FIS experiment template" >}}

{{% notice note %}}
Note: if you've used FIS before you may not see the splash screen. In that case select "Experiment templates" in the menu on the left and access "Create experiment template" from there.
{{% /notice %}}

For our first experiment we will jump around in the definition page so follow closely.

### Template name

First, let's give our template a short name to be used on the list page. To do this scroll to the "Tags" section at the bottom, select "Add new tag", then enter `Name` in the "Key" field and `RebootRDSInstance` for "Value"

{{< img "create-template-2-name.en.png" "Set FIS template name" >}}

### Template description and permissions

Next let's set description and role for the first run of the experiment. Scroll back to the "Description and permission" section at the top. For "Description" enter `RebootRDSInstance` and for "Role" select the `FisWorkshopServiceRole` role you created above.

{{< img "create-template-2-description.en.png" "Set FIS description and role" >}}

### Target selection

Now we need to define targets. Scroll to the "Targets" section and select "Add Target"

{{< img "create-template-2-targets-1.en.png" "Add FIS target" >}}

On the "Add target" popup enter `FisWorkshopRDSDB` for name and select `aws:rds:cluster`. For "Target method" we will select resources based on the ID. Select the `Resource IDs` checkbox. Pick the target cluster then Pick `All` from "Selection mode". Select "Save".

{{< img "create-template-2-targets-2.en.png" "Add FIS target" >}}

### Action definition

With targets defined we define the action to take. Scroll to the "Actions" section" and select "Add Action"

{{< img "create-template-2-actions-1.en.png" "Add FIS actions" >}}

For "Name" enter `RDSInstanceReboot` and you can skip the Description. For "Action type" select `aws:rds:reboot-db-instances`.

If you using a Multi-AZ database you can use the parameter forceFailover by passing true value, and this will failover the database to the standby.

We will leave the "Start after" section blank since the instances we are terminating are part of an autoscaling group and we can let the autoscaling group create new instances to replace the terminated ones.

Under "Target" select the `FisWorkshopRDSDB` target created above. Select "Save".

{{< img "create-template-2-actions-2.en.png" "Add FIS actions" >}}

### Creating template without stop conditions

Scroll to the bottom of the template definition page and select "Create experiment template". Since we didn't specify a stop condition we receive a warning,
This is ok, for this experiment we don't need a stop condition. Type `create` in the text box as indicated and select "Create experiment template".

{{< img "create-template-3-confirm.en.png" "Save FIS template" >}}

## Run FIS experiment

To start the experiment navigate to the [FIS console](https://console.aws.amazon.com/fis/home?#ExperimentTemplates), select the `RebootRDSInstance` template we just created.  Under "Actions" select "Start experiment".

{{< img "start-experiment-1.en.png" "Start experiment add tags" >}}

Let's give the experiment run a friendly name for finding it later on the list page. Under "Experiment tags" enter `Name` for "Key and `FisWorkshopExp1Run1`then select "Start experiment".

{{< img "start-experiment-2.en.png" "Start experiment confirmation" >}}

Because you are about to start a potentially destructive process you will be asked to confirm that you really want to do this. Type `start` as directed and select "Start experiment".

{{< img "start-experiment-3.en.png" "Start experiment" >}}

## Review results

If you are not already on the pane viewing your experiment, navigate to the [FIS console](https://console.aws.amazon.com/fis/home?#Experiments), select "Experiments", and select the experiment ID for the experiment you just started.

Look at the "State" entry. If this still shows pending, feel free to select the "Refresh" button a few times until you see a result.

Navigate to the [RDS console](https://console.aws.amazon.com/rds/home), select "Databases" on the left menu, and search for "fisworkshopdb":

{{< img "review-1-rds-1.en.png" "Review ASG" >}}

You'll see database is rebooting now.

{{< img "review-1-rds-2.en.png" "Update ASG" >}}

