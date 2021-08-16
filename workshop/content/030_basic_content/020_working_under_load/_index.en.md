+++
title = "Synthetic User Experience"
weight = 20
+++

To gain insights from our fault-injection tests we want to be able to correlate the user experience with the sysops view we've gained in the previous section. In production we could instrument the clients to send telemetry back to us but in non-production we don't usually have sufficient load to do this - and _you_ probably have better things to do than sit there clicking reload on a browser page while your experiment is running.

## Generating load against our website

In the previous section you navigated to the basic website for our web server setup as well as the sysops performance dashboard. Open a linux terminal and save the URL from the previous page in an environment variable:

```bash
export URL_HOME=[PASTE URL HERE]
```

Next we need to generate load. There are many [load testing tools](https://en.wikipedia.org/wiki/Category:Load_testing_tools) available to generate a variety of load patterns. However, for the purpose of this workshop we have included a lambda function that will make HTTP GET calls to our site and log performance data to CloudWatch. To find the lambda function  navigate to [CloudFormation](https://console.aws.amazon.com/cloudformation/home), select the "**FisStackLoadGen**" stack and click on the "**Outputs**" tab which will show you the lambda function ARN:

{{< img "cloudformation.en.png" "Cloudformation Lambda Function ARN" >}}

and save the Lambda function ARN in another environment variable:

```bash
export LAMBDA_ARN=[PASTE ARN HERE]
```

Finally invoke the lambda function using the AWS CLI: 

```bash
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
  --invocation-type Event \
  invoke.txt 
```

{{% notice warning %}}
If you are running AWS CLI v2, you need to pass the parameter `--cli-binary-format raw-in-base64-out` or you'll get the error "Invalid base64" when sending the payload.
{{% /notice %}}


Now let's add some load. The invocation above will generate 1000 connections per second for 3 minutes. That seems like a lot so we would expect our site performance to degrade and auto scaling to kick in. 

## Explore impact of load

While our load is running let's explore the setup a little more. 

### Webserver logs and metrics

The first thing we want to look at is our webserver logs. Because we are using auto scaling and virtual machines can disappear, we have installed the [Unified CloudWatch Agent](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/UseCloudWatchUnifiedAgent.html) on our webserver to write logs to a [CloudWatch Log Group](https://console.aws.amazon.com/cloudwatch/home?#logsV2:log-groups/log-group/$252Ffis-workshop$252Fasg-access-log). 

{{%expand "Navigating to CloudWatch Log Groups" %}}
Log into the AWS console as described in **Getting Started**. From the "**Services**" dropdown navigate to "**CloudWatch**" under "**Management & Governance**" or use the search bar. On the left hand side expand the burger menu if necessary, then select "**Logs**" and "**Log Groups**". If you have many log groups you can search for `/fis-workshop/asg-access-log`
{{% /expand%}}

{{< img "nginx-log-stream-1.en.png" "Nginx access log group" >}}

Click through on the topmost entry and expand any of the log lines. You may notice that we've modified the nginx output format to use JSON instead of the default format:

{{< img "nginx-log-stream-2.en.png" "Nginx access log" >}}

While not necessary it makes it very easy to create [Metric Filters](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/MonitoringPolicyExamples.html). Navigate back to the `/fis-workshop/asg-access-log` log group and select the "**Metric filters**" tab. You will see that we have created filters to extract the count of responses with HTTP `status` codes in the `2xx` (good responses) and `5xx` (bad responses) ranges. We also created a filter to select all entries that have a `request_time` set. The resulting metrics can be found under  **Metrics** / **All metrics** / **Custom Namespaces** / **fisworkshop**. These are also the metrics for `nginx connection status` and `nginx response time` you saw on the dashboard in the previous section.

Let's look at our dashboard:

{{< img "dashboard-basic-home.en.png" "Load against home page" >}}

That's odd, did anything happen? According to nginx we would think nothing happened. Maybe we should look at what the server CPU and the load runner have to say. For this we have added a more detailed dashboard:

{{< img "dashboard-extended-home.en.png" "Load against home page" >}}

Now it's more clear what happened: we were requesting a small static page and nginx is incredibly efficient. In the `Server CPU` graph we can see minimal CPU utilization at the same time as the load data in the `Customer (load test)` graphs. 

## Increasing the load

Clearly hitting a static page wasn't a good test to validate that our auto scaling setup works as intended. Fortunately the server also exposes a `phpinfo.php` page. Let's try hitting that instead. Define another environment variable and run the load test against the new URL. And because we really want to see scaling, let's run more than one copy:

```bash
export URL_PHP=${URL_HOME}/phpinfo.php

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
    --invocation-type Event \
    invoke-${ii}.txt 
done
```
{{% notice warning %}}
If you are running AWS CLI v2, you need to pass the parameter `--cli-binary-format raw-in-base64-out` or you'll get the error "Invalid base64" when sending the payload.
{{% /notice %}}

While this is running we encourage you to explore CloudWatch logs and create some of your own dashboard views.

{{< img "dashboard-extended-phpinfo.en.png" "Load against phpinfo page" >}}

We finally generated enough load to force a scaling event. We also see how different the user experience is from what nginx reports. The user times out after 2s and as such experiences substantial site unavailability. Nginx in contrast doesn't report this as error because the connection was terminated before being served. We will leave it as an exercise to the reader to figure out more details and will move on to actually running fault injection experiments.



