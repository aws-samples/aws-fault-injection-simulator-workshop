---
title: "Serverless"
chapter: false
weight: 75
services: true
---

FIS currently does not support disrupting serverless execution in [**AWS Lambda**](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html). It is, however, possible to inject chaos actions by decorating the code executed within AWS Lambda. 

In this section we use the open source [**chaos_lambda**](https://github.com/adhorn/aws-lambda-chaos-injection) python library to demonstrate how to

* inject latency into serverless calls,
* change the response code of the serverless function, and
* simulate exceptions in code execution.

A similar JS library, [**failure-lambda**](https://github.com/gunnargrosch/failure-lambda) is described in the [**Serverless Chaos workshop**](https://catalog.us-east-1.prod.workshops.aws/workshops/3015a19d-0e07-4493-9781-6c02a7626c65/en-US/serverless/failure-lambda/fault-injection) and the understanding of the principles should allow the reader to build their own in their preferred language.

## Architecture

In AWS Lambda, serverless functions expose a "handler" function that receives a JSON object and returns a JSON object. We can keep this handler function unchanged by inserting a new wrapper function around the original handler function, e.g. using a [**decorator pattern**](https://en.wikipedia.org/wiki/Decorator_pattern). This wrapper can cause exceptions in lambda function execution before or after customer code is called, can inject latency before or after customer code is called, can modify output thus simulating a failure result, and can even modify input thus triggering failures in the customer function code:

{{< img "serverless.png" "Serverless encapsulation" >}}

In chaos-lambda, to allow injecting failures on-demand, the wrapper function will query an [**SSM Parameter Store parameter **](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html) to check whether failures should be injected at all and, if so, what failures.

To inject failures in the context of an FIS experiment, we will use an [**SSM Automation**](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-automation.html) document to change the value of the SSM Parameter Store parameter and turn on different types of failures.

## Experiment idea

In this section we are focusing on tooling rather than presenting a full experiment, with some guidance on how to expand on the tooling at the end.

Specifically in this section we will inject failures in an API backed by AWS Lambda instrumented with chaos_lambda. We will run an FIS experiment that will, in order:

* inject latency
* inject an error code response
* inject a runtime exception

We will observe these changes by continuously checking response time, response code, and response body.


## Experiment setup

{{% notice note %}}
**The experiment setup section is for reference only. All required components have been created as part of the workshop setup. If you just want to see the serverless fault injection you can skip ahead to "Validation Procedure" below.** 
{{% /notice %}}

{{% notice note %}}
In earlier sections we have described how configure to service roles, create FIS experiment templates, and create SSM automation documents. For this section, we have created all the required resources as part of the infrastructure setup, and we will only outline the configuration process on the console.
{{% /notice %}}


### Prerequisites

We will be using an SSM document to call the SSM PutParameter API. As such, we will require an IAM role that allows `ssm:PutParameter` - see [**template definition in GitHub**](https://github.com/aws-samples/aws-fault-injection-simulator-workshop/blob/main/resources/templates/serverless/template.yaml#L91-L112). Name this role `FisWorkshopLambdaSsmRole`.

We will also need an IAM role that allows FIS to call SSM Automation and pass the above role to SSM - see [**template definition in GitHub**](https://github.com/aws-samples/aws-fault-injection-simulator-workshop/blob/main/resources/templates/serverless/template.yaml#L115-L212). Name this role `FisWorkshopLambdaServiceRole`

Finally, we will need an SSM automation document to put a parameter value - see [**template definition in GitHub**](https://github.com/aws-samples/aws-fault-injection-simulator-workshop/blob/main/resources/templates/serverless/template.yaml#L58-L89). Note that this document will create or overwrite the parameter with a value that disables fault injection. If you create this document manually you will have to construct the ARN as described in the [**Working with SSM documents**]({{< ref "030_basic_content/040_ssm/030_custom_ssm_docs/" >}}) section. 


### General template setup

* Add "Description" of `Inject Lambda Failures`
* Add a "Name" of `FisWorkshopLambdaFailure`
* Select `FisWorkshopLambdaServiceRole` as execution role


### Action definition

We will define multiple actions that we want to run in sequence. This follows the same procedure as before except that we will populate the optional "Start after" selection to sequence action execution. Create the following actions:

* "Name": `S01_EnableLatency`
  * "Action type": `aws:ssm:start-automation-execution`
  * "Start after": leave this empty as the first step starts at the beginning of the experiment
  * "documentArn": the ARN found in the "Outputs" tab of the FisStackServerless [**CloudFormation**](https://console.aws.amazon.com/cloudformation/home?#/stacks/outputs?filteringStatus=active&filteringText=&viewNested=true&hideStacks=false&stackId=FisStackServerless). 
  * "documentParameters": Reformatted here for legibility. For the `AutomationAssumeRole` you will need to insert the ARN of the `FisWorkshopLambdaSsmRole` either from the "Outputs" of the cloudformation stack or from the "Prerequisites" section.
    ```json
    {
        "AutomationAssumeRole": "arn:aws:iam::ACCOUNT_ID:role/FisStackServerless-FisWorkshopLambdaSsmRole-xxxxyyyyzzzz",   
        "FaultParameterValue": "{
            \"is_enabled\":true,
            \"fault_type\":\"latency\",
            \"delay\":400,
            \"error_code\":404,
            \"exception_msg\":\"Fault injected by chaos-lambda\",
            \"rate\":1
        }"
    }
    ```
  * "maxDuration": `1` "Minutes"

* "Name": `S02_Wait1`
  * "Action type": `aws:fis:wait`
  * "Start after": `S01_EnableLatency`
  * duration: `1` "Minutes"

* "Name": `S03_EnableStatusCode`
  * "Action type": `aws:ssm:start-automation-execution`
  * "Start after": `S02_Wait1`
  * "documentArn": the ARN found in the "Outputs" tab of the FisStackServerless [**CloudFormation**](https://console.aws.amazon.com/cloudformation/home?#/stacks/outputs?filteringStatus=active&filteringText=&viewNested=true&hideStacks=false&stackId=FisStackServerless). 
  * "documentParameters": Reformatted here for legibility. For the `AutomationAssumeRole` you will need to insert the ARN of the `FisWorkshopLambdaSsmRole` either from the "Outputs" of the cloudformation stack or from the "Prerequisites" section.
    ```json
    {
        "AutomationAssumeRole": "arn:aws:iam::ACCOUNT_ID:role/FisStackServerless-FisWorkshopLambdaSsmRole-xxxxyyyyzzzz",   
        "FaultParameterValue": "{
            \"is_enabled\":true,
            \"fault_type\":\"status_code\",
            \"delay\":400,
            \"error_code\":404,
            \"exception_msg\":\"Fault injected by chaos-lambda\",
            \"rate\":1
        }"
    }
    ```
  * "maxDuration": `1` "Minutes"

* "Name": `S04_Wait2`
  * "Action type": `aws:fis:wait`
  * "Start after": `S03_EnableStatusCode`
  * duration: `1` "Minutes"

* "Name": `S05_EnableException`
  * "Action type": `aws:ssm:start-automation-execution`
  * "Start after": `S04_Wait2`
  * "documentArn": the ARN found in the "Outputs" tab of the FisStackServerless [**CloudFormation**](https://console.aws.amazon.com/cloudformation/home?#/stacks/outputs?filteringStatus=active&filteringText=&viewNested=true&hideStacks=false&stackId=FisStackServerless). 
  * "documentParameters": Reformatted here for legibility. For the `AutomationAssumeRole` you will need to insert the ARN of the `FisWorkshopLambdaSsmRole` either from the "Outputs" of the cloudformation stack or from the "Prerequisites" section.
    ```json
    {
        "AutomationAssumeRole": "arn:aws:iam::ACCOUNT_ID:role/FisStackServerless-FisWorkshopLambdaSsmRole-xxxxyyyyzzzz",   
        "FaultParameterValue": "{
            \"is_enabled\":true,
            \"fault_type\":\"exception\",
            \"delay\":400,
            \"error_code\":404,
            \"exception_msg\":\"Fault injected by chaos-lambda\",
            \"rate\":1
        }"
    }
    ```
  * "maxDuration": `1` "Minutes"

* "Name": `S06_Wait3`
  * "Action type": `aws:fis:wait`
  * "Start after": `S05_EnableException`
  * duration: `1` "Minutes"

* "Name": `S07_DisableFaults`
  * "Action type": `aws:ssm:start-automation-execution`
  * "Start after": `S06_Wait3`
  * "documentArn": the ARN found in the "Outputs" tab of the FisStackServerless [**CloudFormation**](https://console.aws.amazon.com/cloudformation/home?#/stacks/outputs?filteringStatus=active&filteringText=&viewNested=true&hideStacks=false&stackId=FisStackServerless). 
  * "documentParameters": Reformatted here for legibility. For the `AutomationAssumeRole` you will need to insert the ARN of the `FisWorkshopLambdaSsmRole` either from the "Outputs" of the cloudformation stack or from the "Prerequisites" section.
    ```json
    {
        "AutomationAssumeRole": "arn:aws:iam::ACCOUNT_ID:role/FisStackServerless-FisWorkshopLambdaSsmRole-xxxxyyyyzzzz",   
        "FaultParameterValue": "{
            \"is_enabled\":false,
            \"fault_type\":\"exception\",
            \"delay\":400,
            \"error_code\":404,
            \"exception_msg\":\"Fault injected by chaos-lambda\",
            \"rate\":1
        }"
    }
    ```
  * "maxDuration": `1` "Minutes"

### Target selection

Because we are exclusively using SSM Automation documents, we don't need to specify any targets.


### Creating template without stop conditions

Select **"Create experiment template"** and confirm that you wish to create a template without stop conditions.


## Validation procedure

As part of the workshop setup, we've created a "Hello World" lambda function instrumented with chaos_lambda - see in [**GitHub**](https://github.com/aws-samples/aws-fault-injection-simulator-workshop/blob/main/resources/templates/serverless/assets/fail_python_lambda/app.py).

We will validate our experiment by using curl in [**CloudShell**](https://console.aws.amazon.com/cloudshell/home). To help us focus on only the response message, status code, and duration, we have created a convenient test script that will run in a loop querying the API:

```bash
# Query URL for convenience
SERVERLESS_URL=$( aws cloudformation describe-stacks --stack-name FisStackServerless --query "Stacks[*].Outputs[?OutputKey=='ServerlessFaultApi'].OutputValue" --output text )

cd ~/environment/aws-fault-injection-simulator-workshop/resources/templates/serverless
./test.sh ${SERVERLESS_URL}
```

We should see output similar to this updating about once per second:

```
...
Hello from Lambda! - 200 - 0.134764
Hello from Lambda! - 200 - 0.135114
Hello from Lambda! - 200 - 0.105795
...
```

The output shows us the response from the Lambda function `Hello from Lambda!`, the status code `200` and the response time. Note the average response time as we will inject about 400ms of additional latency as part of the experiment.


## Run serverless failure injection experiment

{{% notice note %}}
We are assuming that you know how to set up a basic FIS experiment and will focus on things specific to this experiment. If you need a refresher see the previous [**First Experiment**]({{< ref "030_basic_content/030_basic_experiment/" >}}) section.
{{% /notice %}}

Keep the CloudShell session running with the curl generating new information about once per second. In a new browser window navigate to the [**AWS Fault Injection Simulator Console**](https://console.aws.amazon.com/fis/home?#Home) and start the experiment:

* use the `FisWorkshopLambdaFailure` template
* add a `Name` tag of `FisWorkshopLambdaFailure1`
* confirm that you want to start the experiment
* ensure that the "State" is `Running`

{{% expand "Troubleshooting" %}}
If the experiment fails to run, review the **Troubleshooting** heading at the bottom of the [**FIS SSM Start Automation Setup**]({{< ref "030_basic_content/030_basic_experiment/" >}}) section. Note that there is a possibility that SSM automation will not start at all. If this is the case, especially if you have manually created any of the resources, double check that you are specifying full ARNs rather than just names in the FIS template.
{{% /expand %}}


In the FIS window select the "Timeline" tab and hit refresh every minute or so. You should see the experiment progressing through the individual states with green indicating finished steps, blue indicating in-progress steps, and grey signifying steps yet to be started:

{{< img "timeline.png" "Experiment timeline" >}}

At the same time, watch the curl output in the CloudShell window. As the experiment transitions from one step to the next you should see the output change, first to increase the latency:

```
...
Hello from Lambda! - 200 - 0.541716
Hello from Lambda! - 200 - 0.513623
Hello from Lambda! - 200 - 0.546924
...
```

then for the latency to return to normal but the response code changing to 404:

```
...
Hello from Lambda! - 404 - 0.113380
Hello from Lambda! - 404 - 0.274236
Hello from Lambda! - 404 - 0.136305
...
```

and finally changing to an error message indicating an exception has occurred during code execution:

```
...
{"message": "Internal server error"} - 502 - 0.215665
{"message": "Internal server error"} - 502 - 0.113820
{"message": "Internal server error"} - 502 - 0.163391
...
```

before returning to normal at the end of the experiment.

Congratulations for completing this lab! In this lab, you walked through running a multi-step experiment, changed an SSM Parameter Store parameter, and injected faults into a Lambda function. 


## Learning and improving

The setup we've shown here provides failure modes similar to those available for instances and containers. For teaching purposes it also has various problems that you can experiment with and use for ideation on how to customize your own serverless fault injection libraries:

* **Parameter resets** - In the example above, we are using FIS to control the parameter value in two separate steps rather than setting / un-setting the parameter using a single long-running SSM document. Therefore, if you stop the FIS experiment prematurely, the parameter will not be reset to a non-impacting configuration. To address this you could add a `RollbackValue` parameter to the SSM document / FIS template and add an `onError` / `onCancel` path to the SSM document as shown in the [aws-fis-templates-cdk](https://github.com/adhorn/aws-fis-templates-cdk) GitHub examples [here](https://github.com/adhorn/aws-fis-templates-cdk/blob/main/lib/fis-upload-ssm-docs/documents/ssma-put-config-parameterstore.yml#L63-L65) and [here](https://github.com/adhorn/aws-fis-templates-cdk/blob/main/lib/fis-upload-ssm-docs/documents/ssma-put-config-parameterstore.yml#L105-L114). You could even read the parameter at the start of the SSM document run, but please consider concurrency implications if another experiment is also changing the parameter.

* **Order of events** - If you are simulating a failure, do you still want the Lambda code to run or not? There is no single correct answer to this question, as it may depend on your business logic. At the time of writing, if you use the `status-code` error, the Lambda code still executes but reports a failure when no failure occurred. Similarly, in the current implementation an exception occurs before executing user code but could be moved to occur after user code. As you create your own versions, ask yourself: what impact would the mismatch between code execution and error reporting have on error handling in downstream systems?

* **Rate limiting** - As we saw in the [**First Experiment**]({{<ref "/030_basic_content/030_basic_experiment/20-experiment-console" >}}), small differences like terminating 50% vs. terminating 1 of an assumed 2 instances can lead to substantially different outcomes. Similarly the pattern of failures in consecutive invocations may matter to your experiment. E.g., sometimes you may want to affect all invocations for the duration of the fault, sometimes you may want to affect up to a certain number of invocations per time unit, and sometimes you may want to affect a certain fraction of invocations. Sometimes you may prefer deterministic outcomes, sometimes you may prefer heuristic outcomes. As you create your own scenarios, you can review the heuristic implementation in [**chaos_lambda**](https://github.com/adhorn/aws-lambda-chaos-injection/blob/a6d10af49ea823dc0d24998fe6d5f5544327fc03/chaos_lambda.py#L282).

