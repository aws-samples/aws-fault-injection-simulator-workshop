---
title: "EC2 spot instances"
chapter: false
weight: 75
services: false
draft: true
---

In this section we will cover how to validate EC2 Spot Instance Interruption behavior.

[**EC2 Spot Instances**](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-spot-instances.html) make spare EC2 capacity available for steep discounts in exchange for returning them when Amazon EC2 needs the capacity back. Because demand for Spot Instances can vary significantly over time, it is always possible that your Spot Instance might be interrupted. 

To help you gracefully handle interruptions, AWS will send [**Spot Instance Interruption notices**](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-interruptions.html#spot-instance-termination-notices) two minutes before Amazon EC2 stops or terminates your Spot Instance. While it is not always possible to predict demand, AWS may occasionally send an [**EC2 rebalance recommendation**](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/rebalance-recommendations.html) signal before sending the Instance interruption notice.

EC2 Spot instances can be used with Auto Scaling groups or as worker nodes for various forms of batch processing. Because nodes in Auto Scaling groups are usually stateless while batch processes usually generate stateful data we will demonstrate fault injection on a batch compute example with [checkpointing](https://en.wikipedia.org/wiki/Application_checkpointing).  


```
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-request-examples.html
aws ec2 request-spot-instances \
  --instance-count 1 \
  --launch-specification '
{
  "ImageId": "ami-0de1377598c572f0b",
  "SecurityGroupIds": [ "sg-02b0434e8ce793b88" ],
  "InstanceType": "t3.small",
  "SubnetId": "subnet-00e36a47c007ede0b",
  "IamInstanceProfile": {
      "Arn": "arn:aws:iam::238810465798:instance-profile/FisStackAsg-ASGInstanceProfile0A2834D7-1DX660M2FWRTR"
  },
  "UserData": "IyEvYmluL2Jhc2gKY2F0ID4vaG9tZS9lYzItdXNlci9zZW5kX21ldHJpY3MucHkgPDxFT1QKIyEvdXNyL2Jpbi9lbnYgcHl0aG9uMwoKaW1wb3J0IGJvdG8zCmltcG9ydCB0aW1lCmltcG9ydCBzeXMKaW1wb3J0IHNpZ25hbAoKZGVmIHNpZ25hbF9oYW5kbGVyKHNpZyxmcmFtZSk6CiAgICBwcmludCgiR3JhY2VmdWwgZXhpdCAtIHJlcG9ydGluZyBmaW5hbCBtZXRyaWNzIC0gY2hlY2twb2ludGVkICVmIiAlIGNoZWNrcG9pbnRfc2F2ZWRfcGVyY2VudGFnZSkKICAgIHN5cy5leGl0KDApCgpzaWduYWwuc2lnbmFsKHNpZ25hbC5TSUdJTlQsIHNpZ25hbF9oYW5kbGVyKQoKZGVmIGdldF9zc21fcGFyYW1ldGVyKGNsaWVudCxuYW1lLGRlZmF1bHRfc2V0dGluZz01KToKICAgIHRyeToKICAgICAgICByZXNwb25zZSA9IGNsaWVudC5nZXRfcGFyYW1ldGVyKAogICAgICAgICAgICBOYW1lPW5hbWUsCiAgICAgICAgICAgIFdpdGhEZWNyeXB0aW9uPVRydWUKICAgICAgICApCiAgICAgICAgIyBwcmludChyZXNwb25zZSkKICAgICAgICB2YWx1ZSA9IGZsb2F0KHJlc3BvbnNlLmdldCgiUGFyYW1ldGVyIix7fSkuZ2V0KCJWYWx1ZSIsc3RyKGRlZmF1bHRfc2V0dGluZykpKSAKICAgICAgICAjIHByaW50KCJWYWx1ZSByZXRyaWV2ZWQ6ICVzPSVmIiAlIChuYW1lLHZhbHVlKSkKICAgICAgICByZXR1cm4gdmFsdWUKICAgIGV4Y2VwdDoKICAgICAgICBwcmludCgiQ291bGRuJ3QgcmVhZCBwYXJhbWV0ZXIgJXMsIHVzaW5nIGRlZmF1bHQgQ2hlY2tQb2ludCBkdXJhdGlvbiIgJSBuYW1lKQogICAgcmV0dXJuIGRlZmF1bHRfc2V0dGluZwoKZGVmIHB1dF9jbG91ZHdhdGNoX3BlcmNlbnRhZ2VzKGNsaWVudCxzYXZlZF9wZXJjZW50YWdlLHVuc2F2ZWRfcGVyY2VudGFnZSk6CiAgICBjbGllbnQucHV0X21ldHJpY19kYXRhKAogICAgICAgIE1ldHJpY0RhdGE9WwogICAgICAgICAgICB7CiAgICAgICAgICAgICAgICAnTWV0cmljTmFtZSc6ICJ1bnNhdmVkIiwKICAgICAgICAgICAgICAgICdVbml0JzogJ1BlcmNlbnQnLAogICAgICAgICAgICAgICAgJ1ZhbHVlJzogdW5zYXZlZF9wZXJjZW50YWdlCiAgICAgICAgICAgIH0sCiAgICAgICAgICAgIHsKICAgICAgICAgICAgICAgICdNZXRyaWNOYW1lJzogImNoZWNrcG9pbnRlZCIsCiAgICAgICAgICAgICAgICAnVW5pdCc6ICdQZXJjZW50JywKICAgICAgICAgICAgICAgICdWYWx1ZSc6IHNhdmVkX3BlcmNlbnRhZ2UKICAgICAgICAgICAgfSwKICAgICAgICBdLAogICAgICAgIE5hbWVzcGFjZT0nZmlzd29ya3Nob3AnCiAgICApCgp0cnk6CiAgICBzc21fY2xpZW50ID0gYm90bzMuY2xpZW50KCdzc20nKQogICAgY3dfY2xpZW50ID0gYm90bzMuY2xpZW50KCdjbG91ZHdhdGNoJykKZXhjZXB0OgogICAgc3NtX2NsaWVudCA9IE5vbmUKICAgIGN3X2NsaWVudCA9IE5vbmUKICAgIHByaW50KCJDb3VsZCBub3QgY29ubmVjdCB0byBBV1MsIGRpZCB5b3Ugc2V0IGNyZWRlbnRpYWxzPyIpCiAgICBzeXMuZXhpdCgxKQoKIyBEdXJhdGlvbiB1bnRpbCBqb2IgY29tcGxldGlvbiBpbiBtaW51dGVzIChzaG91bGQgYmUgMiA8IHggPCAxNSkKam9iX2R1cmF0aW9uX21pbnV0ZXMgPSBnZXRfc3NtX3BhcmFtZXRlcihzc21fY2xpZW50LCdGaXNXb3Jrc2hvcFNwb3RKb2JEdXJhdGlvbicsNSkgCgojIFRpbWUgYmV0d2VlbiBjaGVja3BvaW50cwpjaGVja3BvaW50X2ludGVydmFsX21pbnV0ZXMgPSBnZXRfc3NtX3BhcmFtZXRlcihzc21fY2xpZW50LCdGaXNXb3Jrc2hvcFNwb3RDaGVja3BvaW50RHVyYXRpb24nLDAuMikKCgpzbGVlcF9kdXJhdGlvbl9zZWNvbmRzID0gNjAuMCAqIGpvYl9kdXJhdGlvbl9taW51dGVzIC8gMTAwLjAKY2hlY2twb2ludF9jb3VudGVyX3NlY29uZHMgPSAwLjAKY2hlY2twb2ludF9zYXZlZF9wZXJjZW50YWdlID0gMAoKcHJpbnQoIlN0YXJ0aW5nIGpvYiAoZHVyYXRpb24gJWYgbWluIC8gY2hlY2twb2ludCAlZiBtaW4pIiAlICgKICAgIGpvYl9kdXJhdGlvbl9taW51dGVzLAogICAgY2hlY2twb2ludF9pbnRlcnZhbF9taW51dGVzCikpCnB1dF9jbG91ZHdhdGNoX3BlcmNlbnRhZ2VzKGN3X2NsaWVudCwwLDApCmZvciBpaSBpbiByYW5nZSgxMDApOgogICAgdGltZS5zbGVlcChzbGVlcF9kdXJhdGlvbl9zZWNvbmRzKQoKICAgICMgcmVjb3JkIHByb2dyZXNzIGRhdGEgdGhhdCBjYW4gYmUgbG9zdAogICAgcHV0X2Nsb3Vkd2F0Y2hfcGVyY2VudGFnZXMoY3dfY2xpZW50LGNoZWNrcG9pbnRfc2F2ZWRfcGVyY2VudGFnZSxpaSsxKQoKICAgIGNoZWNrcG9pbnRfY291bnRlcl9zZWNvbmRzICs9IHNsZWVwX2R1cmF0aW9uX3NlY29uZHMKICAgIGNoZWNrcG9pbnRfZmxhZz0oKGNoZWNrcG9pbnRfY291bnRlcl9zZWNvbmRzLzYwLjApID4gY2hlY2twb2ludF9pbnRlcnZhbF9taW51dGVzKQogICAgcHJpbnQoIiVmJSUgY29tcGxldGUgLSBjaGVja3BvaW50PSVzIiAlIChpaSsxLGNoZWNrcG9pbnRfZmxhZykpCiAgICBpZiBjaGVja3BvaW50X2ZsYWc6CiAgICAgICAgcHJpbnQoInJlc2V0dGluZyBmbGFnIikKICAgICAgICBjaGVja3BvaW50X2NvdW50ZXJfc2Vjb25kcyA9IDAuMAogICAgICAgIGNoZWNrcG9pbnRfc2F2ZWRfcGVyY2VudGFnZSA9IGlpKzEKCnB1dF9jbG91ZHdhdGNoX3BlcmNlbnRhZ2VzKGN3X2NsaWVudCwxMDAsMTAwKQoKRU9UCnl1bSBpbnN0YWxsIC15IGpxCnBpcDMgaW5zdGFsbCBib3RvMwpleHBvcnQgQVdTX0RFRkFVTFRfUkVHSU9OPSQoY3VybCAtcyAxNjkuMjU0LjE2OS4yNTQvbGF0ZXN0L2R5bmFtaWMvaW5zdGFuY2UtaWRlbnRpdHkvZG9jdW1lbnQgfCBqcSAtciAnLnJlZ2lvbicpCnB5dGhvbjMgL2hvbWUvZWMyLXVzZXIvc2VuZF9tZXRyaWNzLnB5Cg=="
}
' 2>&1 \
| tee /tmp/spot-result.json

REQUEST_ID=$( cat /tmp/spot-result.json | jq -rc '.SpotInstanceRequests[].SpotInstanceRequestId' )

unset INSTANCE_ID
while [ -z "$INSTANCE_ID" ]; do
  sleep 1

  aws ec2 describe-spot-instance-requests --spot-instance-request-ids ${REQUEST_ID} \
  | tee /tmp/spot-status.json

  INSTANCE_ID=$( cat /tmp/spot-status.json | jq -rc '.SpotInstanceRequests[0].InstanceId')

  echo $INSTANCE_ID

done

aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value="Fis/Spot"
```

State machine snippets
* DescribeSpotInstanceRequests param support for spot request id is broken
* output filter uses JSONpath (not JMESpath)
  * static query works
  * dynamic query with "input" parameters fails because there's no way to define if the '$' is input or output ... 
  * Input is mapped into context but $$ doesn't expand

```json
{
  "Comment": "A description of my state machine",
  "StartAt": "DescribeSpotInstanceRequests",
  "States": {
    "DescribeSpotInstanceRequests": {
      "Type": "Task",
      "Parameters": {
      },
      "End": true,
      "Resource": "arn:aws:states:::aws-sdk:ec2:describeSpotInstanceRequests",
      "ResultSelector": {
        "Scraped.$": "$.SpotInstanceRequests[?(@.SpotInstanceRequestId=='sir-4en69zkq')]",
        "Scraped2.$": "$.SpotInstanceRequests[?(@.SpotInstanceRequestId=='$$.Execution.Input.creation.SpotInstanceRequests[0].SpotInstanceRequestId')]",
        "Context.$": "$$",
        "ZZ.$": "$$.Execution.Input.creation.SpotInstanceRequests[0].SpotInstanceRequestId"
      }
    }
  }
}

```

```json
{
  "Comment": "A description of my state machine",
  "StartAt": "RequestSpotInstances",
  "States": {
    "RequestSpotInstances": {
      "Type": "Task",
      "Parameters": {
        "InstanceCount": 1,
        "LaunchSpecification": {
          "ImageId": "ami-0de1377598c572f0b",
          "SecurityGroupIds": [
            "sg-02b0434e8ce793b88"
          ],
          "InstanceType": "t3.small",
          "SubnetId": "subnet-00e36a47c007ede0b",
          "IamInstanceProfile": {
            "Arn": "arn:aws:iam::238810465798:instance-profile/FisStackAsg-ASGInstanceProfile0A2834D7-1DX660M2FWRTR"
          },
          "UserData": "IyEvYmluL2Jhc2gKY2F0ID4vaG9tZS9lYzItdXNlci9zZW5kX21ldHJpY3MucHkgPDxFT1QKIyEvdXNyL2Jpbi9lbnYgcHl0aG9uMwoKaW1wb3J0IGJvdG8zCmltcG9ydCB0aW1lCmltcG9ydCBzeXMKaW1wb3J0IHNpZ25hbAoKZGVmIHNpZ25hbF9oYW5kbGVyKHNpZyxmcmFtZSk6CiAgICBwcmludCgiR3JhY2VmdWwgZXhpdCAtIHJlcG9ydGluZyBmaW5hbCBtZXRyaWNzIC0gY2hlY2twb2ludGVkICVmIiAlIGNoZWNrcG9pbnRfc2F2ZWRfcGVyY2VudGFnZSkKICAgIHN5cy5leGl0KDApCgpzaWduYWwuc2lnbmFsKHNpZ25hbC5TSUdJTlQsIHNpZ25hbF9oYW5kbGVyKQoKZGVmIGdldF9zc21fcGFyYW1ldGVyKGNsaWVudCxuYW1lLGRlZmF1bHRfc2V0dGluZz01KToKICAgIHRyeToKICAgICAgICByZXNwb25zZSA9IGNsaWVudC5nZXRfcGFyYW1ldGVyKAogICAgICAgICAgICBOYW1lPW5hbWUsCiAgICAgICAgICAgIFdpdGhEZWNyeXB0aW9uPVRydWUKICAgICAgICApCiAgICAgICAgIyBwcmludChyZXNwb25zZSkKICAgICAgICB2YWx1ZSA9IGZsb2F0KHJlc3BvbnNlLmdldCgiUGFyYW1ldGVyIix7fSkuZ2V0KCJWYWx1ZSIsc3RyKGRlZmF1bHRfc2V0dGluZykpKSAKICAgICAgICAjIHByaW50KCJWYWx1ZSByZXRyaWV2ZWQ6ICVzPSVmIiAlIChuYW1lLHZhbHVlKSkKICAgICAgICByZXR1cm4gdmFsdWUKICAgIGV4Y2VwdDoKICAgICAgICBwcmludCgiQ291bGRuJ3QgcmVhZCBwYXJhbWV0ZXIgJXMsIHVzaW5nIGRlZmF1bHQgQ2hlY2tQb2ludCBkdXJhdGlvbiIgJSBuYW1lKQogICAgcmV0dXJuIGRlZmF1bHRfc2V0dGluZwoKZGVmIHB1dF9jbG91ZHdhdGNoX3BlcmNlbnRhZ2VzKGNsaWVudCxzYXZlZF9wZXJjZW50YWdlLHVuc2F2ZWRfcGVyY2VudGFnZSk6CiAgICBjbGllbnQucHV0X21ldHJpY19kYXRhKAogICAgICAgIE1ldHJpY0RhdGE9WwogICAgICAgICAgICB7CiAgICAgICAgICAgICAgICAnTWV0cmljTmFtZSc6ICJ1bnNhdmVkIiwKICAgICAgICAgICAgICAgICdVbml0JzogJ1BlcmNlbnQnLAogICAgICAgICAgICAgICAgJ1ZhbHVlJzogdW5zYXZlZF9wZXJjZW50YWdlCiAgICAgICAgICAgIH0sCiAgICAgICAgICAgIHsKICAgICAgICAgICAgICAgICdNZXRyaWNOYW1lJzogImNoZWNrcG9pbnRlZCIsCiAgICAgICAgICAgICAgICAnVW5pdCc6ICdQZXJjZW50JywKICAgICAgICAgICAgICAgICdWYWx1ZSc6IHNhdmVkX3BlcmNlbnRhZ2UKICAgICAgICAgICAgfSwKICAgICAgICBdLAogICAgICAgIE5hbWVzcGFjZT0nZmlzd29ya3Nob3AnCiAgICApCgp0cnk6CiAgICBzc21fY2xpZW50ID0gYm90bzMuY2xpZW50KCdzc20nKQogICAgY3dfY2xpZW50ID0gYm90bzMuY2xpZW50KCdjbG91ZHdhdGNoJykKZXhjZXB0OgogICAgc3NtX2NsaWVudCA9IE5vbmUKICAgIGN3X2NsaWVudCA9IE5vbmUKICAgIHByaW50KCJDb3VsZCBub3QgY29ubmVjdCB0byBBV1MsIGRpZCB5b3Ugc2V0IGNyZWRlbnRpYWxzPyIpCiAgICBzeXMuZXhpdCgxKQoKIyBEdXJhdGlvbiB1bnRpbCBqb2IgY29tcGxldGlvbiBpbiBtaW51dGVzIChzaG91bGQgYmUgMiA8IHggPCAxNSkKam9iX2R1cmF0aW9uX21pbnV0ZXMgPSBnZXRfc3NtX3BhcmFtZXRlcihzc21fY2xpZW50LCdGaXNXb3Jrc2hvcFNwb3RKb2JEdXJhdGlvbicsNSkgCgojIFRpbWUgYmV0d2VlbiBjaGVja3BvaW50cwpjaGVja3BvaW50X2ludGVydmFsX21pbnV0ZXMgPSBnZXRfc3NtX3BhcmFtZXRlcihzc21fY2xpZW50LCdGaXNXb3Jrc2hvcFNwb3RDaGVja3BvaW50RHVyYXRpb24nLDAuMikKCgpzbGVlcF9kdXJhdGlvbl9zZWNvbmRzID0gNjAuMCAqIGpvYl9kdXJhdGlvbl9taW51dGVzIC8gMTAwLjAKY2hlY2twb2ludF9jb3VudGVyX3NlY29uZHMgPSAwLjAKY2hlY2twb2ludF9zYXZlZF9wZXJjZW50YWdlID0gMAoKcHJpbnQoIlN0YXJ0aW5nIGpvYiAoZHVyYXRpb24gJWYgbWluIC8gY2hlY2twb2ludCAlZiBtaW4pIiAlICgKICAgIGpvYl9kdXJhdGlvbl9taW51dGVzLAogICAgY2hlY2twb2ludF9pbnRlcnZhbF9taW51dGVzCikpCnB1dF9jbG91ZHdhdGNoX3BlcmNlbnRhZ2VzKGN3X2NsaWVudCwwLDApCmZvciBpaSBpbiByYW5nZSgxMDApOgogICAgdGltZS5zbGVlcChzbGVlcF9kdXJhdGlvbl9zZWNvbmRzKQoKICAgICMgcmVjb3JkIHByb2dyZXNzIGRhdGEgdGhhdCBjYW4gYmUgbG9zdAogICAgcHV0X2Nsb3Vkd2F0Y2hfcGVyY2VudGFnZXMoY3dfY2xpZW50LGNoZWNrcG9pbnRfc2F2ZWRfcGVyY2VudGFnZSxpaSsxKQoKICAgIGNoZWNrcG9pbnRfY291bnRlcl9zZWNvbmRzICs9IHNsZWVwX2R1cmF0aW9uX3NlY29uZHMKICAgIGNoZWNrcG9pbnRfZmxhZz0oKGNoZWNrcG9pbnRfY291bnRlcl9zZWNvbmRzLzYwLjApID4gY2hlY2twb2ludF9pbnRlcnZhbF9taW51dGVzKQogICAgcHJpbnQoIiVmJSUgY29tcGxldGUgLSBjaGVja3BvaW50PSVzIiAlIChpaSsxLGNoZWNrcG9pbnRfZmxhZykpCiAgICBpZiBjaGVja3BvaW50X2ZsYWc6CiAgICAgICAgcHJpbnQoInJlc2V0dGluZyBmbGFnIikKICAgICAgICBjaGVja3BvaW50X2NvdW50ZXJfc2Vjb25kcyA9IDAuMAogICAgICAgIGNoZWNrcG9pbnRfc2F2ZWRfcGVyY2VudGFnZSA9IGlpKzEKCnB1dF9jbG91ZHdhdGNoX3BlcmNlbnRhZ2VzKGN3X2NsaWVudCwxMDAsMTAwKQoKRU9UCnl1bSBpbnN0YWxsIC15IGpxCnBpcDMgaW5zdGFsbCBib3RvMwpleHBvcnQgQVdTX0RFRkFVTFRfUkVHSU9OPSQoY3VybCAtcyAxNjkuMjU0LjE2OS4yNTQvbGF0ZXN0L2R5bmFtaWMvaW5zdGFuY2UtaWRlbnRpdHkvZG9jdW1lbnQgfCBqcSAtciAnLnJlZ2lvbicpCnB5dGhvbjMgL2hvbWUvZWMyLXVzZXIvc2VuZF9tZXRyaWNzLnB5Cg=="
        }
      },
      "Resource": "arn:aws:states:::aws-sdk:ec2:requestSpotInstances",
      "ResultPath": "$.creation",
      "Next": "DescribeSpotInstanceRequests"
    },
    "DescribeSpotInstanceRequests": {
      "Type": "Task",
      "End": true,
      "Parameters": {
        "SpotInstanceRequestIds.$":  "$.creation.SpotInstanceRequests[*].SpotInstanceRequestId" 
      },
      "Resource": "arn:aws:states:::aws-sdk:ec2:describeSpotInstanceRequests",
      "ResultPath": "$.query"
    }
  }
}
```

```
STATE_MACHINE_ARN=arn:aws:states:us-west-2:313373485031:stateMachine:SpotChaosStateMachine-wUBB6YJBMJAv

aws stepfunctions start-execution \
  --state-machine-arn ${STATE_MACHINE_ARN} \
  --input '{ "JobDuration": "2", "CheckpointDuration": "0.2", "WaitForJobFinish": { "Percentage": 100 }}'
```
