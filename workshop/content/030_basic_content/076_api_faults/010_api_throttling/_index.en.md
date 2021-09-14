---
title: "API Throttling"
weight: 10
services: true
---

## Experiment idea

AWS [**throttles**](https://docs.aws.amazon.com/AWSEC2/latest/APIReference/throttling.html#throttling-monitor) API requests for each AWS account on a per-region basis.  Amazon does this to help ensure the performance of all services, and to ensure fair usage for all AWS customers.

As an AWS account grows in resources and usage, API usage is likely to grow as well, potentially exceeding quotas. As such, handling API throttling events is an important design consideration as you build applications that rely on the availablility of AWS APIs.  

AWS developers considered this when building their SDKs.  Each AWS SDK implements automatic [**retry logic**](https://docs.aws.amazon.com/general/latest/gr/api-retries.html).  Our experiment looks as follows:

* **Given**: We are using AWS SDKs in a serverless application
* **Hypothesis**: The SDK will manage AWS API retries during API throttling conditions and eventually (in time for dependent services) return a successful response.

## Environment setup

We will be using a simple serverless application that returns the response of an `ec2:DescribeInstances` API call.  A Lambda function will run our serverless application and an API Gateway will be used to proxy the request from the client to the Lambda function.

### CloudFormation resources

As part of resource setup this workshop created the required resources using the `api-throttling.yaml` file in the [**GitHub repo**](https://github.com/aws-samples/aws-fault-injection-simulator-workshop/blob/main/resources/templates/api-failures/api-throttling.yaml). 

Navigate to the [**CloudFormation console**](https://console.aws.amazon.com/cloudformation/home?#/stacks?filteringText=FisApiFailureThrottling&viewNested=true&hideStacks=false&filteringStatus=active) and in the stack outputs note the values of `apiGatewayInvokeUrl` and `iamRole`.

{{< img "Stack-outputs.en.png" "Stack Outputs" >}}

## Experiment setup

### General template setup

We will be creating a new experiment template in FIS

* Create a new experiment template
  * Add "Name" tag of `FisWorkshopApiThrottle`
  * Add "Description" of `ApiThrottling`
  * Select `FisWorkshopServiceRole` as "execution role"

### Target Selection

In the target selection, click add target.  

Inside the target modal, enter `FISWorkshopApiLambda` for "Name" and select `aws:iam:role` for "Resource type".  The "Target method" should be left as `Resource IDs` and then enter the role value that you obtained from the Cloudformation stack output.  

The selection mode should read as "All".  When done select "Save".  

{{< img "throttle-target.en.png" "Throttle Target" >}}

### Action definition

With a target defined we need define the action to take. Scroll to the "Actions" section and select "Add Action"

Type `APIThrottle` for" Name".  For "Action type", select `aws:fis:inject-api-throttle-error`.  Select the target you created in the previous section.  It should read `FISWorkshopApiLambda`.  

In the Action parameters section set the following fields:
- duration: `Minutes 3`
- operations: `DescribeInstances`
- percentage: `75`
- service: `ec2`

Hit "Save" and then select "Create experiment template". 

{{< img "throttle-action.en.png" "Throttle Target" >}}

### Creating template without stop conditions

* Confirm that you wish to create the template without stop condition

## Validation procedure

Before we validate our hypothesis, we need to understand what normal state is.  We have read that the SDK automatically handles retries, but what impact will adding throttling to our environment have and how will we be able to measure that impact? 

For that, we will be using [Curl](https://curl.se/) to make a request to the url endpoint that was created during the environment setup. Use the `apiGatewayInvokeUrl` you noted from the CloudFormation stack outputs earlier, e.g.:

```bash
THROTTLE_URL=[replace with apiGatewayInvokeUrl]
curl ${THROTTLE_URL}
```

You will see a result that looks similar to:

```{'InstanceIds': ['i-036173389128de59b'], 'RetryAttempts': 0}```

{{% notice note %}}
The list of Ids will be different in your environment depending on how many ec2 instances are running.
{{% /notice %}}

`RetryAttempts` are hopefully at 0 in your test.  Any number above 0 indicates that the API call received an error response.  

For reference, the relavant part of our application that we are testing reads:

```python
import boto3

ec2 = boto3.client('ec2')

def describe_instances():
  resp = ec2.describe_instances(
    Filters=[{
              'Name': 'instance-state-name',
              'Values': ['running']
    }]
  )
  
  instance_ids = [ i['Instances'][0].get('InstanceId') for i in resp['Reservations']]
  
  return {
    "InstanceIds": instance_ids,
    "RetryAttempts": resp['ResponseMetadata'].get('RetryAttempts')
  }
```

## Run FIS experiment

### Start the experiment

Within FIS

* Select the `FisWorkshopApiThrottle` experiment template you created above 
* Select start experiment
* Add a `Name` tag of `FisWorkshopThrottleRun1`
* Confirm that you want to start an experiment

Going back to the curl command, lets go ahead and fire off another request.  Is the `RetryAttempts` value still at 0?  Remember that we set throttling to *75%* in our experiment template so it is possible that the response was the same as the previous attempt.  Lets run several more requests to see if we notice any difference when we increase the volume of traffic.

```bash
for i in {1..10}
do
  curl ${THROTTLE_URL}
done
```

Did you see a failure message or an increase in retries?  Did you notice any difference in response times?  

## Learning and Improving

In this scenario, a Lambda function is using the AWS Boto3 SDK to integrate with the EC2 DescribeInstances API.  By default, it will retry an API call 5 times before raising the error.  You can reference Boto3 [documentantion](https://boto3.amazonaws.com/v1/documentation/api/latest/guide/retries.html) for complete details.  

Remember we set our experiment to throttle at a rate of `75%`?  From our curl calls, not all requests failed, but its likely you had at least 1 error.  During times of high volume many more requests would have failed.  To address these failures, we are going to increase the amount of retries to raise our chance of success.  

Open up the [**Lambda console**](https://console.aws.amazon.com/lambda/home).  Navigate to the `fis-workshop-api-errors-throttling` function and browse to the "Code source" section.  We will use the embedded editor to update our code.  

Add the following block under the import boto3 line.  Be sure to remove the existing ec2 variable declaration.  

```python
from botocore.config import Config

config = Config(
   retries = {
      'max_attempts': 10,
      'mode': 'standard'
   }
)

ec2 = boto3.client('ec2', config=config)

```

Your final function should look like:

{{< img "lambda-retry.en.png" "Lambda Retry" >}}

Click the "Deploy" button above the editor

### Re-run experiment

Back in the [FIS console](https://console.aws.amazon.com/fis/home?#ExperimentTemplates), start a new experiment from the same template as earlier.  Tag this experiment with "Name" `FisWorkshopThrottleRun2` and start the experiment.

Re-run the same loop curl command.  Do you see retry counts >= 5?  Did you receive any errors or timeouts?  

### Conclusion

Even after updating our configuration to retry up to 10 times, we likely still saw at least 1 error from our multiple requests to our endpoint.  Why did this happen?  Extending our retries in our library only considers the integration between our application code and the AWS EC2 api.  It does not account for the other pieces of our architecture that may be impacted up increasing the retry account.  In this example, we also need to consider the maximum time our Lambda function is configured to run (30 seconds), and the hard limit our API Gateway requires a response from our Lambda function (30 seconds).  By increasing the retry count, we also increased the time it would take for the AWS SDK to complete the call or return a response.  

This is a great example of the tradeoff of increasing retries.  Sometimes it makes sense to increase this value to ensure completion of a certain action.  For example, in background batch jobs where response times are not as critical, increasing retries might provide a mechanism that results in less failures during high throttling rates.  In contrast, in applications that benefit from faster responses, such as synchrounous web application integrations, it might make more sense to reduce the retry count to handle failures sooner.  