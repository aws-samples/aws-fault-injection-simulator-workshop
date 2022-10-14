import boto3
import json
client = boto3.client("lambda")
def script_handler(events, context):
    function_name = events.get("FunctionName","")
    replicas = events.get("Replicas",1)
    results = []
    for ii in range(replicas):
        try:
            response = client.invoke(
                FunctionName=function_name,
                InvocationType='Event',
                Payload=json.dumps(events.get("InputPayload",{})).encode("utf8"),
            )
            print(ii)
            print(response)
            results.append({ 
                "RequestId": response.get("ResponseMetadata",{}).get("RequestId","none"), 
                "StatusCode": response.get("StatusCode",500)
            })
        except:
            results.append({ 
                "RequestId": "none", 
                "StatusCode": 500
            })
    return {
        "response": json.dumps(results)
    }

res = script_handler({
  "FunctionName": "arn:aws:lambda:us-west-2:313373485031:function:FisStackLoadGen-LoadGenerator0277BB85-OHaLmI1YhktQ",
  "Replicas": 3,
  "InputPayload": {
    "TlsTimeoutMilliseconds": 2000,
    "ConnectionTargetUrl": "http://FisSt-FisAs-1MTDL2VCSSK17-1482927173.us-west-2.elb.amazonaws.com/phpinfo.php",
    "ReportingMilliseconds": 1000,
    "ConnectionTimeoutMilliseconds": 2000,
    "ConnectionsPerSecond": 1000,
    "ExperimentDurationSeconds": 180,
    "TotalTimeoutMilliseconds": 2000
}},None)

print(res)