---
title: "API Unavailable"
weight: 20
---

## Experiment idea

In the last module we discussed handling AWS API throtting.  In that module our example showed an application that `read` data.  What about a scenario that includes `writing, updating, or deleting` data.  Does increasing retries apply here as well? In this module we are going to simulate unavailability of an AWS API and how that relates to mutating calls.  

* **Given**: We are using AWS SDKs in a serverless application
* **Hypothesis**: The SDK will manage AWS API retries during high rates of API errors and eventually (in time for dependent services) return a successful response.

## Environment setup

The same serverless application approach will be used in this module to return the same `ec2:DescribeInstances` API call.  In this module, we are also adding a capability to destroy instances which represents our mutation call.  We will be updating our existing CloudFormation stack to deploy additional code to our lambda function as well as updates to our Amazon API Gateway (API Gateway).  We will also be creating an SQS queue and a t3.micro ec2 instance.  

{{% notice note %}}
This workshop will not impact any ec2 instances outside of this module.  An IAM role is used to only allow terminate instances against the instance ID deployed by the CloudFormation stack.  An additional safeguard is also included in the application's logic.  
{{% /notice %}}

### CloudFormation resources

As part of resource setup this workshop created the required resources using the `api-unavailable.yaml` file in the [**GitHub repo**](https://github.com/aws-samples/aws-fault-injection-simulator-workshop/blob/main/resources/templates/api-failures/api-unavailable.yaml). 

Navigate to the [**CloudFormation console**](https://console.aws.amazon.com/cloudformation/home?#/stacks?filteringText=FisApiFailureUnavailable&viewNested=true&hideStacks=false&filteringStatus=active) and in the stack outputs note the values of `apiGatewayInvokeUrl`, `iamRole` and `InstancdeId`. The additional `InstanceId` value is the ID of an EC2 instance that was created specifically for the instance termination flow described below.

{{< img "Stack-outputs.en.png" "Stack Outputs" >}}

## Experiment setup

### General template setup

We will be creating a new experiment template in FIS

* Create a new experiment template
  * Add "Name" tag of `FisWorkshopUnavailable`
  * Add "Description" of `ApiUnavailable`
  * Select `FisWorkshopServiceRole` as "execution role"

### Target Selection

In the target selection, click add target.  

Inside the target modal, enter `FISWorkshopApiLambda` for "Name" and select `aws:iam:role` for "Resource type".  The "Target method" should be left as `Resource IDs` and then enter the role value that you obtained from the CloudFormation stack output.  

{{% notice note %}}
When selecting the IAM role, ensure you only add the role that includes lambda in the name
{{% /notice %}}  

The selection mode should read as "All".  When done hit "Save".  

{{< img "error-target.en.png" "Throttle Target" >}}

### Action definition

With a target defined we need define the action to take. Scroll to the "Actions" section and select "Add Action"

Type `APIError` for "Name".  For "Action type", select `aws:fis:inject-api-unavailble-error`. Select the target you created in the previous section.  It should read `FISWorkshopApiLambda`.  

In the Action parameters section set the following fields:
- duration: `Minutes 3`
- operations: `DescribeInstances,TerminateInstances`
- percentage: `100`
- service: `ec2`

Hit "Save" and then select "Create expiriment template". 

{{< img "error-action.en.png" "Throttle Target" >}}

### Creating template without stop conditions

* Confirm that you wish to create the template without stop condition

## Validation Procedure

Just as we did in the last module, we will use curl to validate our environment prior to starting the experiment.  Run the curl command with the new URL you noted from the CloudFormation stack:

```bash
UNAVAILABLE_URL=[replace with apiGatewayInvokeUrl]
curl ${UNAVAILABLE_URL}
```

This should result in the same response as the previous module

```
{'InstanceIds': ['i-0823fd3823e25afd3', 'i-036173389128de59b'], 'RetryAttempts': 0}
```

In the list of IDs displayed you should see the ID you noted from the outputs section of the CloudFormation stack.  When we run the experiment, we will use a different endpoint that will result in a mutation call and issue a termination of this instance.  

## Run FIS experiment

### Start the experiment

Within FIS

* Select the `FisWorkshopApiUnavailable` experiment template you created above 
* Select start experiment
* Add a `Name` tag of `FisWorkshopUnavailableRun1`
* Confirm that you want to start an experiment

Instead of issuing the same request, we are going to add the **/terminate** path to our API Gateway url.  This path is configured to `mock` an endpoint that will terminate the ec2 instance that was created for this experiment.  

```bash
TERMINATION_URL=${UNAVAILABLE_URL}/terminate
curl ${TERMINATION_URL}
```

With the experiment running, we should receive an error:

`{"message": "Internal server error"}`

While the experiment runs and we continue to call the terminate endpoint, we will continue to receive this error.  During service outages that result in 100% unavailability errors, all calls will fail to complete.  

## Learning and Improving

In situations where APIs are unreliable or you want to minimize the scope of the impact during API unavailability, you may want to consider using asynchronous patterns to process incoming requests.  So far in this module, all of the testing has been using synchronous call patterns.  

[**Asynchronous Design Patterns**](https://aws.amazon.com/blogs/compute/managing-backend-requests-and-frontend-notifications-in-serverless-web-apps/) allow for faster client responses and the ability to limit the impact of call failures.  Implementing queues and asynchronous processing of requests seperates the processing of those requests from the injestion process.  

In this environment, we have added an [**Amazon Simple Queueing Service**](https://aws.amazon.com/sqs/) (SQS) queue to store the request for asynchronous processing.  Instead of our request being sent directly to the lambda function for processing, we will have our API Gateway write directly to the SQS queue.  In this pattern, the lambda function will attempt to process this request from the queue, and will continue to retry asynchronously until the mutating call completes.  

In [**FIS**](https://console.aws.amazon.com/fis/home) ensure the experiment is still running.  If not, start a new experiment with Name tag `FisWorkshopUnavailableRun2`.  

When the experiment begins running issue a new curl request to the `/terminate` path, but this time with a `POST` action.  HTTP `POST` methods are usually used for mutating actions.  

```bash
curl -X POST curl ${TERMINATION_URL}
```

Even with the experiment running you should receive a response that looks similar to

```
{"SendMessageResponse":{"ResponseMetadata":{"RequestId":"8cc4bb0a-6dbf-595b-995d-e2ac3d9e3622"},"SendMessageResult":{"MD5OfMessageAttributes":null,"MD5OfMessageBody":"74ed192a7c4e541bf34668d1e8ef0027","MD5OfMessageSystemAttributes":null,"MessageId":"5a454f05-b5f9-48ee-8511-222144fbef01","SequenceNumber":null}}}
```

This response was generated from the `sqs:SendMessage` API initiated from our API Gateway and not affected by the specific EC2 throttling.  

To confirm the message was sent to the queue, navigae to the [sqs console](https://console.aws.amazon.com/sqs/v2/home) and the click "Queues" > "fis-workshop-api-queue"

Under the "Monitoring" tab you should see a count in the "Number of Messages Received"

{{< img "sqs-messages.en.png" "SQS Messages" >}}

When the experiment completes after running 3 minutes, you can verify that the instance with the ID from the stack output is in the process of terminating.  

## Conclusion 

In this module, we used an SQS queue message to ensure that the TerminateInstances API call would be retried after the fault injection to demonstrate how you can use asynchronous API patterns to mitigate API failures.  