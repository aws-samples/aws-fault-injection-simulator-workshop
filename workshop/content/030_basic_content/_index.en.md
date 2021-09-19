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

This workshop is focused on how to inject fault into an existing infrastructure. For this purpose the template in the [**Provision AWS resources**]({{< ref "020_starting_workshop/050_create_stack" >}}) section sets up a variety of components. Throughout this workshop we will be showing you architecture diagrams focusing on only the components relevant to the section, e.g.:

{{< img "BasicASG.png" "Image of architecture to be injected with chaos" >}}

You can click on these images to enlarge them.

{{% expand "Click to expand if you are hosting a demo" %}}

If you are hosting a demo you should start generating load now. This will pull the relevant variables from AWS CloudFormation:

```bash
export LAMBDA_ARN=$( aws cloudformation describe-stacks --stack-name FisStackLoadGen --query "Stacks[*].Outputs[?OutputKey=='LoadGenArn'].OutputValue" --output text )
export URL_HOME=$( aws cloudformation describe-stacks --stack-name FisStackAsg --query "Stacks[*].Outputs[?OutputKey=='FisAsgUrl'].OutputValue" --output text )
export URL_PHP=${URL_HOME}/phpinfo.php

echo $LAMBDA_ARN
echo $URL_HOME
echo $URL_PHP
```

For convenience here is the light load snippet expanded for 900s runs:

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

{{% notice warning %}}
If you are running AWS CLI v2, you need to pass the parameter `--cli-binary-format raw-in-base64-out` or you'll get the error "Invalid base64" when sending the payload.
{{% /notice %}}


For convenience is here the heavy load snippet:

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

{{% /expand %}}
