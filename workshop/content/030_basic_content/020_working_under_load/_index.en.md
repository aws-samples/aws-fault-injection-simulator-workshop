---
title: "Synthetic User Experience"
weight: 20
services: true
---

In the previous section we showed you a typical configuration to collect sysops data but without visibility into the actual user experience. To gain end-to-end insights from our fault injection experiments, we want to correlate user-experience with the sysops view from the previous section. In production, we could instrument the clients to send telemetry back to us, but in non-production we don't usually have sufficient load to do this.  _You_ also probably have better things to do than sit there clicking reload on a browser page while your experiment is running. 

In this section we will show you how to generate and record synthetic load to reflect the user experience:

{{< img "BasicASG-with-user-and-synthetics.png" "Image of architecture to be injected with chaos" >}}

## Generating load against our website

In the previous section, you navigated to the basic website setup as well as the sysops performance dashboard. Open a linux terminal and save the URL from the previous page in an environment variable:

```bash
export URL_HOME=[PASTE URL HERE]
```

Next, we need to generate load. There are many [**load testing tools**](https://en.wikipedia.org/wiki/Category:Load_testing_tools) available to generate a variety of load patterns. However, for the purpose of this workshop we have included an AWS Lambda (Lambda) function that will make HTTP GET calls to our website and log performance data to Amazon CloudWatch (CloudWatch). To find the Lambda function, navigate to the AWS CloudFormation (CloudFormation) [**console**](https://console.aws.amazon.com/cloudformation/home), select the `FisStackLoadGen` stack, and click on the "**Outputs**" tab. It will show you the Lambda function ARN:

{{< img "cloudformation.en.png" "Cloudformation Lambda Function ARN" >}}

Save the Lambda function ARN in another environment variable:

```bash
export LAMBDA_ARN=[PASTE ARN HERE]
```

Finally, invoke the Lambda function using the AWS CLI: 

```bash
# Workaround for AWS CLI v1/v2 compatibility issues
CLI_MAJOR_VERSION=$( aws --version | grep '^aws-cli' | cut -d/ -f2 | cut -d. -f1 )
if [ "$CLI_MAJOR_VERSION" == "2" ]; then FIX_CLI_PARAM="--cli-binary-format raw-in-base64-out"; else unset FIX_CLI_PARAM; fi

# Run load for 3min
aws lambda invoke \
  --function-name ${LAMBDA_ARN} \
  --payload "{
        \"ConnectionTargetUrl\": \"${URL_HOME}\", 
        \"ExperimentDurationSeconds\": 180,
        \"ConnectionsPerSecond\": 1000,
        \"ReportingMilliseconds\": 1000,
        \"ConnectionTimeoutMilliseconds\": 2000,
        \"TlsTimeoutMilliseconds\": 2000,
        \"TotalTimeoutMilliseconds\": 2000
    }" \
  $FIX_CLI_PARAM \
  --invocation-type Event \
  /dev/null 
```

{{% notice info %}}
If you are running AWS CLI v2, you need to pass the parameter `--cli-binary-format raw-in-base64-out` or you'll get the error "Invalid base64" when sending the payload. This notice is for troubleshooting, the code above should work for both CLI versions.
{{% /notice %}}


Now, let's generate some load. The invocation above will generate 1000 connections per second for 3 minutes. We expect our website's performance to degrade and for Auto Scaling to kick in. 

## Explore impact of load

While our load is running let's explore the setup a little more. 

### Webserver logs and metrics

The first thing we want to look at is our webserver logs. Because we are using an Auto Scaling group, virtual machines can be terminated and recycled which means logs written locally on the EC2 instance won't be accessible anymore. Therefore, we have installed the [**Unified CloudWatch Agent**](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/UseCloudWatchUnifiedAgent.html) and configured our webserver to write logs to a [**CloudWatch Log Group**](https://console.aws.amazon.com/cloudwatch/home?#logsV2:log-groups/log-group/$252Ffis-workshop$252Fasg-access-log). 

{{%expand "Navigating to CloudWatch Log Groups" %}}
Log into the AWS console as described in [**Start the workshop**]({{< ref "020_starting_workshop" >}}). From the "**Services**" dropdown navigate to "**CloudWatch**" under "**Management & Governance**" or use the search bar. On the left hand side expand the burger menu if necessary, then select "**Logs**" and "**Log Groups**". If you have many log groups you can search for `/fis-workshop/asg-access-log`
{{% /expand%}}

{{< img "nginx-log-stream-1.en.png" "Nginx access log group" >}}

Click through on the topmost entry and expand any of the log lines. You may notice that we've modified the Nginx output format to use JSON instead of the default format:

{{< img "nginx-log-stream-2.en.png" "Nginx access log" >}}

While not necessary, this makes it easy to create [**Metric Filters**](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/MonitoringPolicyExamples.html). Navigate back to the `/fis-workshop/asg-access-log` log group and select the "**Metric filters**" tab. You will see that we have created filters to extract the count of responses with HTTP `status` codes in the `2xx` (good responses) and `5xx` (bad responses) ranges. We also created a filter to select all entries that have a `request_time` set. The resulting metrics can be found under  **Metrics** / **All metrics** / **Custom Namespaces** / `fisworkshop`. These are also the metrics for `Server (nginx) connection status` and `Server (nginx) response time` you saw on the dashboard in the previous section.

Let's look at our dashboard:

{{< img "dashboard-basic-home.en.png" "Load against home page" >}}

That's odd, did anything happen? According to Nginx, it looks like nothing happened. Remember the falling tree in the forest and no one is around to hear it? We need to look at what the server CPU and the load runner. For this, we have added a more detailed dashboard:

{{< img "dashboard-extended-home.en.png" "Load against home page" >}}

Now, it's clearer what happened. We were requesting a small static page and Nginx is really efficient. In the `Server CPU` graph, we can see minimal CPU utilization correlating with the load data in the `Customer (load test)` graphs. 

## Increasing the load

Clearly, hitting a static page isn't a good test to validate our Auto Scaling configuration works as intended. Fortunately, the server also exposes a `phpinfo.php` page. Let's try loading that instead. Define another environment variable and run the load test against the new URL. Since we want to see the Auto Scaling group adjust capacity, let's run more than one copy:

```bash
export URL_PHP=${URL_HOME}/phpinfo.php

# Workaround for AWS CLI v1/v2 compatibility issues
CLI_MAJOR_VERSION=$( aws --version | grep '^aws-cli' | cut -d/ -f2 | cut -d. -f1 )
if [ "$CLI_MAJOR_VERSION" == "2" ]; then FIX_CLI_PARAM="--cli-binary-format raw-in-base64-out"; else unset FIX_CLI_PARAM; fi

# Run load for 5min, 3x in parallel because max per lambda is 1000
for ii in 1 2 3; do
  aws lambda invoke \
    --function-name ${LAMBDA_ARN} \
    --payload "{
          \"ConnectionTargetUrl\": \"${URL_PHP}\", 
          \"ExperimentDurationSeconds\": 300,
          \"ConnectionsPerSecond\": 1000,
          \"ReportingMilliseconds\": 1000,
          \"ConnectionTimeoutMilliseconds\": 2000,
          \"TlsTimeoutMilliseconds\": 2000,
          \"TotalTimeoutMilliseconds\": 2000
      }" \
    $FIX_CLI_PARAM \
    --invocation-type Event \
    /dev/null 
done
```
{{% notice info %}}
If you are running AWS CLI v2, you need to pass the parameter `--cli-binary-format raw-in-base64-out` or you'll get the error "Invalid base64" when sending the payload. This notice is for troubleshooting, the code above should work for both CLI versions.
{{% /notice %}}

While this is executing, we encourage you to explore CloudWatch logs and create some dashboard views of your own.

{{< img "dashboard-extended-phpinfo.en.png" "Load against phpinfo page" >}}

According to the dashboards, we've now generated enough load to force a scaling event. We can also see how different the user experience is from the Nginx report. Requests timeout after 2s, substantially affecting user experiences, and rendering the website unavailable. Nginx, in contrast, doesn't report this as an error because the connection was terminated by the client before being served. We will leave it as an exercise to the reader to figure out more details and will move on to fault injection experiments.



