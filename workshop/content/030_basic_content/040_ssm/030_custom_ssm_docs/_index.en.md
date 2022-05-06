---
title: "Working with SSM documents"
weight: 30
services: true
---

## Pre-configured SSM documents

The linux CPU stress experiment we saw in the previous section used one of the [**pre-configured SSM documents**](https://docs.aws.amazon.com/fis/latest/userguide/actions-ssm-agent.html#fis-ssm-docs) to run a script on our Linux instance. 

To find the script, navigate to the [**AWS Systems Manager console**](https://console.aws.amazon.com/systems-manager/documents?), scroll down in the left-hand menu all the way to the bottom to **"Documents"**, select **"Owned by Amazon"**, and search for `AWSFIS`. Note that this search may take a few seconds to display results.

{{< img "find-ssm.en.png" "Locate FIS SSM documents" >}}

To inspect the script, click on the script name, i.e. `AWSFIS-Run-CPU-Stress`, then select the **"Content"** tab. 

{{< img "look-at-ssm.en.png" "Examine SSM documents" >}}

The document is a YAML file defining two `aws:runShellScript` actions: `InstallDependencies` to install the `stress-ng` package, and `ExecuteStressNg` to inject CPU stress. 

## Custom SSM documents

Currently AWS does not provide a CPU stress document for Windows, but we can create our own as shown in the next section. For more information on writing SSM documents please see these resources:

* [**AWS Systems Manager documentation**](https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-ssm-docs.html)
* [**Writing your own SSM documents blog**](https://aws.amazon.com/blogs/mt/writing-your-own-aws-systems-manager-documents/)
* [**AWS SSM workshop**](https://workshop.aws-management.tools/ssm/capability_hands-on_labs/documents/)

If you want to see an example how one might inject stress, you can have a look at the `WinStressDocument` resource in the [**CloudFormation template**](https://github.com/aws-samples/aws-fault-injection-simulator-workshop/blob/main/resources/templates/cpu-stress/CPUStressInstances.yaml). Alternatively you can follow the same search procedure as for the AWS owned documents but search the **"Owned by me"** or **"Shared by me"** tabs instead of **"Owned by AWS"**.

For additional SSM sample documents relating to FIS see these resources

* **https://github.com/adhorn/chaos-ssm-documents**

### Working with custom SSM documents in FIS

While writing custom SSM documents is outside the scope of this workshop, there are a few aspects of SSM documents you should be aware of:

* **Document ARN** - FIS requires the full SSM document ARN. The ARN can easily be constructed from the document name (and the owner account ID if the template is shared with you) using this format string: `arn:${AWS::Partition}:ssm:${AWS::Region}:${AWS::AccountId}:document/${WinStressDocument}`
* **Exit status** - Shell script convention is to signal success with a return/exit value of `0` and a failure with any non-zero numeric value. If FIS detects a non-zero exit status on an SSM script it will mark the action as "Failed", terminate all running actions, cancel queued actions, invoke any outstanding roll-back actions, cancel experiment execution, and mark the overall experiment as "Failed".
* **Duration** - FIS actions have a "Duration" setting and will stop action execution if the action has not finished within this time period. For SSM actions this will ["**cancel**"](https://docs.aws.amazon.com/systems-manager/latest/userguide/rc-cancel.html) the command. If the command has a sequence of steps, this will result in only some of the steps being executed. 
* **onCancel** / **onFailure** - SSM provides you with a means to ensure that automation can fail / clean-up safely by providing `onCancel` and `onFailure` [properties](https://docs.aws.amazon.com/systems-manager/latest/userguide/automation-actions.html) on each step. These properties allow designating clean-up steps to perform.

