---
title: "Hypothesis & Experiment"
chapter: false
weight: 10
services: true
---

## Experiment idea

In this section we want to ensure that our containerized application running on Amazon EKS is designed in a fault tolerant way, so that even if an instance in the cluster fails our application is still available. Let's validate this:

* **Given**: we have a containerized application running on Amazon EKS exposing a web page.
* **Hypothesis**: failure of a single worker node instance will not adversely affect our application. The web page will continue to be available.

## Experiment setup

{{% notice note %}}
We are assuming that you know how to set up a basic FIS experiment and will focus on things specific to this experiment. If you need a refresher see the previous [**First Experiment**]({{< ref "030_basic_content/030_basic_experiment/" >}}) section.
{{% /notice %}}

### General template setup

{{% notice note %}}
We are assuming that you have already set up an IAM role for for this workshop. If you haven't, see the [**Create FIS Service Role**]({{< ref "030_basic_content/030_basic_experiment/10-permissions" >}}) section.
{{% /notice %}}

Create a new experiment template:
  * add `Name` tag of `FisWorkshopEKS`
  * add `Description` of `Terminate EKS Worker Node`
  * select `FisWorkshopServiceRole` as execution role

### Target selection

Now we need to define targets. Scroll to the "Targets" section and select "Add Target"

{{< img "create-template-2-targets-1.en.png" "Add FIS target" >}}

On the "Add target" popup enter `FisWorkshopEKSWorkerNode` for name and select `aws:ec2:instance`. For "Target method" we will dynamically select resources based on an associated tag. Select the `Resource tags and filters` checkbox. Pick `Count` from "Selection mode" and enter `1`. Under "Resource tags" enter `eks:nodegroup-name` in the "Key" field and `FisWorkshopNG` for "Value". Under filters enter `State.Name` in the "Attribute path" field and `running` under "Values". Select "Save".

{{< img "create-template-2-targets-2.en.png" "Add FIS target" >}}

**_Note:_** we are using the `aws:ec2:instance` action instead of the `aws:eks:nodegroup` action because currently the latter cannot terminate a single running worker node. 

### Action definition

With targets defined we define the action to take. Scroll to the "Actions" section" and select "Add Action"

{{< img "create-template-2-actions-1.en.png" "Add FIS actions" >}}

For "Name" enter `EKSWorkerNodeTerminate` and you can skip the Description. For "Action type" select `aws:ec2:terminate-instances`.

We will leave the "Start after" section blank since the instances we are terminating are part of an EKS Managed Node Group and we can let the Managed Node Group create new instances to replace the terminated ones.

Under "Target" select the `FisWorkshopEKSWorkerNode` target created above. Select "Save".

{{< img "create-template-2-actions-2.en.png" "Add FIS actions" >}}

### Creating template without stop conditions

Confirm that you wish to create the template without stop condition.

{{< img "create-template-3-confirm.en.png" "Confirm No Stop Conditions" >}}

## Validation procedure

Before running the experiment we should consider how we will define success. Let's check the webpage we are hosting. To find the URL of the webpage navigate to the [CloudFormation console](https://console.aws.amazon.com/cloudformation/home?#/stacks?filteringStatus=active&filteringText=FisStackEks&viewNested=true&hideStacks=false), select the `FisStackEks` stack, Select "Outputs", and copy the value of "FisEksUrl".

Open the URL in a new tab to validate that our website is in fact up and running:

{{< img "hello-kubernetes-app.en.png" "Hello Kubernetes App" >}}

How will we know that our instance failure was in fact non-impacting? For this workshop we'll be using a simple Bash script that continuously polls our application.

### Starting the validation procedure

In your local terminal, run the following script. For your convenience we are automating the query for the load balancer URL but you could also paste the URL you've found above:

```bash
# Query URL for convenience
EKS_URL=$( aws cloudformation describe-stacks --stack-name FisStackEks --query "Stacks[*].Outputs[?OutputKey=='FisEksUrl'].OutputValue" --output text )

# Busy loop queries. CTRL-C to end loop
while true; do
  curl -sLo /dev/null -w 'Code %{response_code} Duration %{time_total} \n' ${EKS_URL}
done
```

We would expect that all requests will return a [HTTP 200](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/200) OK code with some variability in the request duration, meaning the application is still responding successfully. Healthy output should look like this:

```text
Code 200 Duration 0.140314 
Code 200 Duration 0.086206 
Code 200 Duration 0.085946 
Code 200 Duration 0.084102 
Code 200 Duration 0.085972 
```

Leave the script running while we run the FIS experiment next.

## Run FIS experiment

### Record current application state

In a new browser window navigate to the load balancer URL you copied earlier, this is your application endpoint. Notice that the application is currently running:

{{< img "hello-kubernetes-app.en.png" "Hello Kubernetes App" >}}

You can also verify the HTTP return code using this command, replacing `REPLACE_WITH_EKS_SERVICE_ALB_URL` with the load balancer DNS name you copied earlier:

```bash
curl -IL <REPLACE_WITH_EKS_SERVICE_ALB_URL> | grep "^HTTP\/"
```

### Start the experiment

* select the `FisWorkshopEKS` experiment template you created above 
* select **Start experiment** from the **Action** drop-down menu
* add a `Name` tag of `FisWorkshopEKSRun1`
* confirm that you want to start an experiment

{{< img "start-experiment-3.en.png" "Confirm Start Experiment" >}}
