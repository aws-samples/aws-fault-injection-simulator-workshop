+++
title = "First Experiment"
date =  2021-04-14T17:25:17-06:00
weight = 3
+++

In this section we will cover the setup required for running FIS and run our first experiment

## Experiment idea

In the [previous section]({{< ref "/030_basic_content/020 working under load" >}}) we ensured that we can measure the user experience. We have also configured an autoscaling group that should ensure that we can "always" provide a good experience to the customer. Let's validate this:

* **Given**: we have an autoscaling group with multiple instances
* **Hypothesis**: failure of a single EC2 instances may lead to slower response times but our customers will always have service.


{{%expand "Expand if you are running a demo" %}}

If you are running a demo you should start generating load now. This will pull the relevant variables from CloudFormation:

```bash
export LAMBDA_ARN=$( aws cloudformation describe-stacks --stack-name FisStackLoadGen --query "Stacks[*].Outputs[?OutputKey=='LoadGenArn'].OutputValue" --output text )
export URL_HOME=$( aws cloudformation describe-stacks --stack-name FisStackAsg --query "Stacks[*].Outputs[?OutputKey=='FisAsgUrl'].OutputValue" --output text )
export URL_PHP=${URL_HOME}/phpinfo.php

echo $LAMBDA_ARN
echo $URL_HOME
echo $URL_PHP
```

For convenience here the light load snippet expanded for 900s runs:

```bash
# Run light load for 15min (max single lambda execution time)
aws lambda invoke \
  --function-name ${LAMBDA_ARN} \
  --payload "{
        \"ConnectionTargetUrl\": \"${URL_HOME}\", 
        \"ExperimentDurationSeconds\": 900,
        \"ConnectionsPerSecond\": 1000,
        \"ReportingMilliseconds\": 1000,
        \"ConnectionTimeoutMilliseconds\": 2000,
        \"TlsTimeoutMilliseconds\": 2000,
        \"TotalTimeoutMilliseconds\": 2000
    }" \
  --invocation-type Event \
  invoke.txt 
```

For convenience here the heavy load snippet:

```bash
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
