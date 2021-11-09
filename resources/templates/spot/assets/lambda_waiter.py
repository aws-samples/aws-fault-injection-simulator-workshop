import json
import boto3

dynamodb = boto3.resource('dynamodb')

def lambda_handler(event, context):
    # TODO implement
    print(event)
    print(context)

    table = dynamodb.Table('DDBTest1')
    response = table.put_item(
       Item={
            'RunId': event["InstanceId"],
            "JobId":  event["ExecutionId"],
            'HeartbeatToken': event["HeartbeatToken"],
            "JobDuration": event["JobDuration"],
            "CheckpointDuration": event["CheckpointDuration"],
            "Percentage": event["Percentage"],
        }
    )

    return {
        'statusCode': 200,
        'body': json.dumps('Dummy function succeeded')
    }
