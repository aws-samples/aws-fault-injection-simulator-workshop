---
title: "Workshop"
chapter: true
weight: 30
services: true
---

This workshop is broken into multiple chapters. The chapters are designed to be done in sequence with each chapter assuming familiarity with some concepts from previous chapters and focusing on new learnings. We include refresher links to relevant prior sections to help you skip over materials you are already familiar with.


## Chapters:

{{% children %}}{{% /children %}}

## Architecture Diagrams

This workshop is focused on how to inject fault into an existing infrastructure. For this purpose the template in the [**Provision AWS resources**]({{< ref "020_starting_workshop/010_self_paced/050_create_stack" >}}) section sets up a variety of components. Throughout this workshop we will be showing you architecture diagrams focusing on only the components relevant to the section, e.g.:

{{< img "BasicASG.png" "Image of architecture to be injected with chaos" >}}

You can click on these images to enlarge them.

{{% expand "Click to expand if you are hosting a demo" %}}

If you are hosting a demo you should start generating load now. This will pull the relevant variables from AWS CloudFormation, run 
"light" load for 15min (900s), and run additional "heavy" load for 5min (300s) after 5min of "light" load.

{{% notice info %}}
If you are running AWS CLI v2, you need to pass the parameter `--cli-binary-format raw-in-base64-out` or you'll get the error "Invalid base64" when sending the payload. This notice is for troubleshooting, the code below should work for both CLI versions.
{{% /notice %}}


```bash
# Get resource information
export LAMBDA_ARN=$( aws cloudformation describe-stacks --stack-name FisStackLoadGen --query "Stacks[*].Outputs[?OutputKey=='LoadGenArn'].OutputValue" --output text )
export URL_HOME=$( aws cloudformation describe-stacks --stack-name FisStackAsg --query "Stacks[*].Outputs[?OutputKey=='FisAsgUrl'].OutputValue" --output text )
export URL_PHP=${URL_HOME}/phpinfo.php

echo $LAMBDA_ARN
echo $URL_HOME
echo $URL_PHP

# Workaround for AWS CLI v1/v2 compatibility issues
CLI_MAJOR_VERSION=$( aws --version | grep '^aws-cli' | cut -d/ -f2 | cut -d. -f1 )
if [ "$CLI_MAJOR_VERSION" == "2" ]; then FIX_CLI_PARAM="--cli-binary-format raw-in-base64-out"; else unset FIX_CLI_PARAM; fi

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
  $FIX_CLI_PARAM \
  --invocation-type Event \
  /dev/null

# Wait for 5min before starting additional heavy load
sleep 300

# Run heavy load for 5min
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
    $FIX_CLI_PARAM \
    /dev/null 
done
```

{{% /expand %}}
