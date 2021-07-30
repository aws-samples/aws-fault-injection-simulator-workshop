+++
title = "Hypothesis & Experiment"
chapter = false
weight = 10
+++

## Experiment idea

In this section we want to ensure that our containerized application running on Amazon ECS is designed in a fault tolerant way, so that even if an instance in the cluster fails our application is still available. Let's validate this:

* **Given**: we have a containerized application running on Amazon ECS
* **Hypothesis**: failure of a single container instance will not adversely affect our application.

## Experiment setup

{{% notice note %}}
We are assuming that you know how to set up a basic FIS experiment and will focus on things specific to this experiment. If you need a refresher see the previous [**First Experiment**]({{< ref "030_basic_content/030 basic experiment/" >}}) section.
{{% /notice %}}

### General template setup

{{% notice note %}}
We are assuming that you have already set up an IAM role for for this workshop. If you haven't, see the [**Create FIS Service Role**]({{< ref "030_basic_content/030 basic experiment/10-permissions" >}}) section.
{{% /notice %}}

Create a new experiment template:
  * add `Name` tag of `FisWorkshopECS`
  * add `Description` of `Terminate ECS Cluster Instance`
  * select `FisWorkshopServiceRole` as execution role

### Target selection

Now we need to define targets. Scroll to the "Targets" section and select "Add Target"

{{< img "create-template-2-targets-1.en.png" "Add FIS target" >}}

On the "Add target" popup enter `FisWorkshopECSInstance` for name and select `aws:ec2:instance`. For "Target method" we will dynamically select resources based on an associated tag. Select the `Resource tags and filters` checkbox. Pick `Count` from "Selection mode" and enter `1`. Under "Resource tags" enter `Name` in the "Key" field and `EcsStack/EcsAsgProvider` for "Value". Under filters enter `State.Name` in the "Attribute path" field and `running` under "Values". Select "Save".

{{< img "create-template-2-targets-2.en.png" "Add FIS target" >}}

### Action definition

With targets defined we define the action to take. Scroll to the "Actions" section" and select "Add Action"

{{< img "create-template-2-actions-1.en.png" "Add FIS actions" >}}

For "Name" enter `ECSInstanceTerminate` and you can skip the Description. For "Action type" select `aws:ec2:terminate-instances`.

We will leave the "Start after" section blank since the instances we are terminating are part of an autoscaling group and we can let the autoscaling group create new instances to replace the terminated ones.

Under "Target" select the `FisWorkshopECSInstance` target created above. Select "Save".

{{< img "create-template-2-actions-2.en.png" "Add FIS actions" >}}

### Creating template without stop conditions

Confirm that you wish to create the template without stop condition.

{{< img "create-template-3-confirm.en.png" "Confirm No Sto Conditions" >}}

## Validation procedure

Before running the experiment we should consider how we will define success. How will we know that our instance failure was in fact non-impacting. For this workshop we'll be using a simple Bash script that continuosly polls our application:

```bash
while true; do
curl -IL <REPLACE_WITH_ECS_SERVICE_ALB_URL> | grep "^HTTP\/"
done
```

We would expect that all requests will return a `HTTP 200 OK` code, meaning the application is still responding successfully Healthy output should look like this:

```text
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
HTTP/1.1 200 OK
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
HTTP/1.1 200 OK
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
HTTP/1.1 200 OK
```

### Starting the validation procedure

In a new browser window navigate to the *Load Balancers* section in the [EC2 console](https://console.aws.amazon.com/ec2/v2/home?#LoadBalancers:sort=loadBalancerName) and search for a load balancer named `EcsSt-Sampl-AB12CD34EF56`, e.g. `EcsSt-Sampl-1999ODF3QKB3Q `. Select the load balancer and copy the **DNS name** value from the *Description* tab below:

{{< img "load-balancer-dns.en.png" "Load Balancer DNS name" >}}

In your local terminal, start the bash script, replacing `REPLACE_WITH_ECS_SERVICE_ALB_URL` with the load balancer DNS name you just copied:

```bash
while true; do
curl -IL <REPLACE_WITH_ECS_SERVICE_ALB_URL> | grep "^HTTP\/"
done
```

Leave the script running while we run the FIS experiment next.

## Run FIS experiment

### Record current application state

In a new browser window navigate to the load balancer URL you copied earlier, this is your application endpoint. Notice that the application is currently running:

{{< img "ecs-sample-app.en.png" "ECS Sample App" >}}

You can also verify the HTTP return code using this command, replacing `REPLACE_WITH_ECS_SERVICE_ALB_URL` with the load balancer DNS name you copied earlier:

```bash
curl -IL <REPLACE_WITH_ECS_SERVICE_ALB_URL> | grep "^HTTP\/"
```

### Start the experiment

* select the `FisWorkshopECS` experiment template you created above 
* select **Start experiment** from the **Action** drop-down menu
* add a `Name` tag of `FisWorkshopECSRun1`
* confirm that you want to start an experiment

{{< img "start-experiment-3.en.png" "Confirm Start Experiment" >}}