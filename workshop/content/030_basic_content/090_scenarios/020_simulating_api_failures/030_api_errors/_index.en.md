+++
title = "API Errors"
weight = 10
+++

In the last module we discussed handling of AWS API throttling.  In your testing, even after you updated the SDK's config, you may have still seen errors due to timeouts.  You should always think about architechting for failure.   In this module we are going to explore complete API failures and a potential pattern you implement to mitigate impact.  

## Update Expirement Template

Back in [FIS](https://console.aws.amazon.com/fis/home), we are going to update the expirement template we created in the last module to inject API failures at 100%.  This expirement will simulate the scenario where an AWS's service is completely unavailable.

Use the left panel to navigate to your Expirement Templates.  Select the template created during the last module, and using the action button, select update expirement template.  

Click edit on the existing action.  

Update the Action Type to *aws:fis:inject-api-unavailble-error*

Update the following fields to these values:

- duration: *Minutes 5*
- operations: *DescribeInstances*
- percentage: *100*
- service: *ec2*

Save the action and be sure to click update expirement template. 

When the template is successfully saved, use the action button again to start the expirment.  

##Run Curl Request

Just as we did in the last section, we are going to issue a single curl command to the same endpoint.  

```bash
curl https://drncx40xx5.execute-api.us-east-1.amazonaws.com/v1
```

This should result in an error message that looks like

```{"message": "Endpoint request timed out"}```

This is because our application code is still set to retry on failures for a maximum of 10 times.  The exponential backoff behavior of AWS SDK's will exceed our API Gateway's 30 second response limit.  We have the failure percentage set to 100% so this call will fail for the duration of the 5 minute expirement.  

## Mitigation

In situations where APIs are unreliable or you want to minimize the scope of the impact during api unavailability, you may want to consider using asynchronous patterns to process incoming requests.  So far in this module, all of the testing has been using synchronous call patterns.  

[Asynchronous Design Patterns]](https://aws.amazon.com/blogs/compute/managing-backend-requests-and-frontend-notifications-in-serverless-web-apps/) allows for faster client responses and the ability to limit the impact of call failures.  Implementing queues and asynchronous processing of requests seperates the processing of those requests from the injestion process.  

In our environment, we will be adding an [SQS](https://aws.amazon.com/sqs/) queue to store the request for processing the curl request.   

## Stack Update

We are going to update the stack we created during the last module.  Navigagte to the [console](https://console.aws.amazon.com/cloudformation/home) and select the stack and click update.

Select replace current template and in the proceeding screen, upload a file created from saving the following code block or download the example [template]({{< ref "../../../../../resources/templates/api-failures/01-apigw-lambda.yaml" >}}).

Upload the new template leaving the default paramters as-is.  

## Rerun expirment

Going back to [FIS](https://console.aws.amazon.com/fis/home) we want to start the same expirement template. Once the expirement is running, re-issue the previous curl request.  This call should fail.  

The updated stack includes several new resources and code changes.  As part of those changes, you can not submit the same call through a HTTP post call to the same URL.  While this is not a practical use case of when you would implement an asynchronous call, it will demonstrate a pattern that can be used to *hide* API errors from your customers.  

```bash
curl -XPOST https://drncx40xx5.execute-api.us-east-1.amazonaws.com/v1
```

If you want to run another loop to post several requests

```bash
for i in {{1..10}}
do
curl -XPOST https://drncx40xx5.execute-api.us-east-1.amazonaws.com/v1
done
```

The lambda function that was responsible for injesting our earlier request using an HTTP GET request is now placing those requests on a queue.  To verify, you can navigate to [SQS](https://console.aws.amazon.com/sqs/v2/home) and navigate to your queues.  Here you should see *Messages available* in the fis-workshop-queue.  

{{< img "sqs-messages.en.png" "SQS Messages" >}}


## Conclusion 

In this module we demonstrated how you can use FIS to inject API failures into your AWS account and some strategies you can use to account for those failures in your applications.  