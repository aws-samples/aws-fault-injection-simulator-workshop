# Goad redux

Inspired by https://goad.io/ focuses on bare-bones load testing. Like goad it uses AWS Lambda to run a load test but as opposed to goad it does not currently scale across multiple lambdas.

In contrast to goad, the resource creation in AWS has been pulled out of the go code and moved to SAM. 

In addition to running a load test, this project also records the resulting performance metrics to CloudWatch to allow graphing side-by-side with server side metrics. Metrics can be written via EMF (currently that's limited to 1 minute resolution) or CloudWatch PutMetrics API calls (at 1s resolution). The default is to use the latter.

Invocation of the Lambda function is done via CLI/invoke:

```
# Generic - Non-Blocking
export TARGET_URL=[URL TO GET]
export LAMBDA_ARN=[ARN OF LAMBDA, FROM CLOUDFORMATION]
aws lambda invoke \
  --function-name ${LAMBDA_ARN} \
  --payload "{
        \"ConnectionTargetUrl\": \"${TARGET_URL}\", 
        \"ExperimentDurationSeconds\": 120,
        \"ConnectionsPerSecond\": 1000,
        \"ReportingMilliseconds\": 1000,
        \"ConnectionTimeoutMilliseconds\": 2000,
        \"TlsTimeoutMilliseconds\": 2000,
        \"TotalTimeoutMilliseconds\": 2000,
    }" \
  --invocation-type Event \
  invoke.txt 
```

`ConnectionTargetUrl` is required, all other values are optional. For execution in AWS Lambda the maximum `ConnectionsPerSecond` is limited to about `1000` by Lambda limiting the maximum open file handles setting to `1024`. 
