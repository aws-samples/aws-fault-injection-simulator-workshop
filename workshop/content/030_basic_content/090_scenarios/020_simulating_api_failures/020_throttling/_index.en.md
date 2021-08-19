+++
title = "API Throttling"
weight = 10
+++

Amazon [throttles](https://docs.aws.amazon.com/AWSEC2/latest/APIReference/throttling.html#throttling-monitor) API requests for each AWS account on a per-region basis.  Amazon does this to help ensure ther performance of the services, and to ensure fair usage for all AWS customers.

As an AWS account grows in resourses and usage, API usage is likely grow as well.  Handling API throttling events is an important design consideration as you build applications that rely on the availablility of AWS APIs.  

##Setup

This module provides a [Cloudformation template](({{< ref "../../../../../resources/templates/api-failures/01-apigw-lambda.yaml" >}})) to set up the necessary infrastructure for this scenario.  In your aws console create a new Cloudformation stack and name it *fis-workshop-api-failure*

```yaml
---
AWSTemplateFormatVersion: 2010-09-09
Description: FIS ApiGateway
Parameters:
  apiGatewayName:
    Type: String
    Default: fis-workshop
  apiGatewayStageName:
    Type: String
    AllowedPattern: "[a-z0-9]+"
    Default: v1
  apiGatewayHTTPMethod:
    Type: String
    Default: ANY
  lambdaFunctionName:
    Type: String
    AllowedPattern: "[a-zA-Z0-9]+[a-zA-Z0-9-]+[a-zA-Z0-9]+"
    Default: fis-workshop-api-failure
Resources:
  apiGateway:
    Type: AWS::ApiGateway::RestApi
    Properties:
      Description: Example API Gateway
      EndpointConfiguration:
        Types:
          - REGIONAL
      Name: !Ref apiGatewayName

  apiGatewayRootMethod:
    Type: AWS::ApiGateway::Method
    Properties:
      AuthorizationType: NONE
      HttpMethod: !Ref apiGatewayHTTPMethod
      Integration:
        IntegrationHttpMethod: POST
        Type: AWS_PROXY
        Uri: !Sub
          - arn:aws:apigateway:${AWS::Region}:lambda:path/2015-03-31/functions/${lambdaArn}/invocations
          - lambdaArn: !GetAtt lambdaFunction.Arn
      ResourceId: !GetAtt apiGateway.RootResourceId
      RestApiId: !Ref apiGateway

  apiGatewayDeployment:
    Type: AWS::ApiGateway::Deployment
    DependsOn:
      - apiGatewayRootMethod
    Properties:
      RestApiId: !Ref apiGateway
      StageName: !Ref apiGatewayStageName

  lambdaFunction:
    Type: AWS::Lambda::Function
    Properties:
      Code:
        ZipFile: |
          import boto3

          ec2 = boto3.client('ec2')

          def describe_instances():
            ret = ec2.describe_instances()
            return ret

          def handler(event,context):
            return {
              "body": f"{describe_instances()}",
              "headers": {
                "Content-Type": "text/plain"
              },
              'statusCode': 200
            }
      Description: FIS Workshop
      FunctionName: !Ref lambdaFunctionName
      Handler: index.handler
      MemorySize: 128
      Role: !GetAtt lambdaIAMRole.Arn
      Runtime: python3.8

  lambdaApiGatewayInvoke:
    Type: AWS::Lambda::Permission
    Properties:
      Action: lambda:InvokeFunction
      FunctionName: !GetAtt lambdaFunction.Arn
      Principal: apigateway.amazonaws.com
      SourceArn: !Sub arn:aws:execute-api:${AWS::Region}:${AWS::AccountId}:${apiGateway}/${apiGatewayStageName}/${apiGatewayHTTPMethod}/

  lambdaIAMRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: 2012-10-17
        Statement:
          - Action:
              - sts:AssumeRole
            Effect: Allow
            Principal:
              Service:
                - lambda.amazonaws.com
      Policies:
        - PolicyDocument:
            Version: 2012-10-17
            Statement:
              - Action:
                  - logs:CreateLogGroup
                  - logs:CreateLogStream
                  - logs:PutLogEvents
                Effect: Allow
                Resource:
                  - !Sub arn:aws:logs:${AWS::Region}:${AWS::AccountId}:log-group:/aws/lambda/${lambdaFunctionName}:*
          PolicyName: lambda
        - PolicyDocument:
            Version: 2012-10-17
            Statement:
              - Action:
                  - ec2:DescribeInstances
                Effect: Allow
                Resource: "*"
          PolicyName: DescribeInstances

  lambdaLogGroup:
    Type: AWS::Logs::LogGroup
    Properties:
      LogGroupName: !Sub /aws/lambda/${lambdaFunctionName}
      RetentionInDays: 90

Outputs:
  apiGatewayInvokeURL:
    Value: !Sub https://${apiGateway}.execute-api.${AWS::Region}.amazonaws.com/${apiGatewayStageName}
```

When the stack creation process completes, grab the invoke URL for the API Gateway resource by browsing the Outputs tab  

{{< img "Stack-outputs.en.png" "Stack Outputs" >}}

## Testing in normal conditions

The URL provides an endpoint that returns a result from the EC2 DescribeInstances API. 
To test, issue the curl command against the apiGatewayInvokeURL value

```bash
curl https://drncx40xx5.execute-api.us-east-1.amazonaws.com/v1
```

Depending on the instances in your account, the results will look different.  Take note of the field *RetryAttempts* value.  It should be 0 if there were no errors calling the DescribeInstances API.  

##Create Throttling Expiriment

Now we will test the same endpoint under throttling conditions.  To introduce API throtting we will create a new FIS expirement through the [console](https://console.aws.amazon.com/fis/home)

Click the Create expirement template button 

For description type *API Expirement* and select the *FISWorkshopServiceRole* for IAM role.  

### Add Target
Next add a target for this expirement template.  Name the target *FISLambda* and for the Resource type field select *aws:iam:role*.  Leave the target method as Resource IDs and select the role created during the stack creation.  The role will begin with fis-workshop-api-failure-*.  

Leave Selection mode as "All" and hit save

{{< img "throttle-target.en.png" "Throttle Target" >}}

### Add Action

Type *APIFailure* for Name.  For Action Type, select *aws:fis:inject-api-throttle-error*.  Select the target you created in the previous section.  It should read *FISLambda*.  

In the Action parameters section set the following fields:
- duration: *Minutes 5*
- operations: *DescribeInstances*
- percentage: *75*
- service: *ec2*

In the Tags section, add a new tag *Name* with a value of *APIExpirement*.

Hit Save and then Create expiriment template.  

## Begin Expirement

To begin the Throttle expirment, use the Action button and select Start

Remember that curl command we issued to test under normal conditions?  Re run that same command from your terminal and see what happens.  What value is now in the *RetryAttempts* field?  Was it still 0 or did you recieve a message "Internal server error"?  

Since we set the throttle rate to *75%* lets issue the curl command several times in a row. 

```bash
for i in {1..10}
do
curl https://drncx40xx5.execute-api.us-east-1.amazonaws.com/v1
done
```

Did you see a failure message or an increased in retries?  

## Handle Throttle Conditions

Because AWS uses throttling as a way to ensure fair access to AWS APIs, it is important to ensure our code accounts for throttling possibilites.  

In this scenario, a lambda function is using the AWS Boto3 SDK to integrate with the EC2 DescribeInstances API.  By default, it will retry an API call 5 times before raising the error.  You can reference Boto3 [documentantion]https://boto3.amazonaws.com/v1/documentation/api/latest/guide/retries.html for complete details.  

Remember we set our experiment to throttle at a rate of 75%?  From our curl calls, not all requests failed, but its likely you had at least 1 error.  During times of high volume, many more requests would have failed.  To address these failures, we are going to increase the ammount of retries to increase our chance of success.  

Open up the lambda [console](https://console.aws.amazon.com/lambda/home).  Navigate to the *fis-workshop-api-throttle* function and browse to the "Code source" section.  We will use the embedded editor to update our code.  

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

## Retest

Navigate back to FIS and look at the experiment that we conducted in a previous step.  It is likely Completed by now so we will have to start a new experiment.  Navigate to Expirement templates and start the APIThrottle expirement again. 

Re-run the loop curl command.  Do you see retry counts >= 5?  Did you receive any errors or timeouts?  

## Conclusion 

By using AWS SDKs and ensuring reasonable retry counts, we were able to reduce the amount of errors we surfaced to the client.  Keep in mind the type of integration and the impact to customer experience when determining the right balance of retries and responding to requests.  

