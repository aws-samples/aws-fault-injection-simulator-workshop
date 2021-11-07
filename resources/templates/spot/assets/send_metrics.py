#!/usr/bin/env python3

import boto3
import time
import sys
import signal

checkpoint_saved_percentage = 0

def signal_handler(sig,frame):
    print(signal.Signals(sig))
    print("Graceful exit - reporting final metrics - checkpointed %f" % checkpoint_saved_percentage)
    sys.exit(0)

catchable_sigs = set(signal.Signals) - {signal.SIGKILL, signal.SIGSTOP, signal.SIGCHLD}
for sig in catchable_sigs:
    print("handle %s" % sig)
    signal.signal(sig, signal_handler)

def get_ssm_parameter(client,name,default_setting=5):
    try:
        response = client.get_parameter(
            Name=name,
            WithDecryption=True
        )
        # print(response)
        value = float(response.get("Parameter",{}).get("Value",str(default_setting))) 
        # print("Value retrieved: %s=%f" % (name,value))
        return value
    except:
        print("Couldn't read parameter %s, using default CheckPoint duration" % name)
    return default_setting

def put_cloudwatch_percentages(client,saved_percentage,unsaved_percentage):
    client.put_metric_data(
        MetricData=[
            {
                'MetricName': "unsaved",
                'Unit': 'Percent',
                'Value': unsaved_percentage,
                'StorageResolution': 1
            },
            {
                'MetricName': "checkpointed",
                'Unit': 'Percent',
                'Value': saved_percentage,
                'StorageResolution': 1
            },
        ],
        Namespace='fisworkshop'
    )

try:
    ssm_client = boto3.client('ssm')
    cw_client = boto3.client('cloudwatch')
except:
    ssm_client = None
    cw_client = None
    print("Could not connect to AWS, did you set credentials?")
    sys.exit(1)

# Duration until job completion in minutes (should be 2 < x < 15)
job_duration_minutes = get_ssm_parameter(ssm_client,'FisWorkshopSpotJobDuration',5) 

# Time between checkpoints
checkpoint_interval_minutes = get_ssm_parameter(ssm_client,'FisWorkshopSpotCheckpointDuration',0.2)


sleep_duration_seconds = 60.0 * job_duration_minutes / 100.0
checkpoint_counter_seconds = 0.0

print("Starting job (duration %f min / checkpoint %f min)" % (
    job_duration_minutes,
    checkpoint_interval_minutes
))
put_cloudwatch_percentages(cw_client,0,0)
for ii in range(100):
    time.sleep(sleep_duration_seconds)

    # record progress data that can be lost
    put_cloudwatch_percentages(cw_client,checkpoint_saved_percentage,ii+1)

    checkpoint_counter_seconds += sleep_duration_seconds
    checkpoint_flag=((checkpoint_counter_seconds/60.0) > checkpoint_interval_minutes)
    print("%f%% complete - checkpoint=%s" % (ii+1,checkpoint_flag))
    if checkpoint_flag:
        print("resetting flag")
        checkpoint_counter_seconds = 0.0
        checkpoint_saved_percentage = ii+1

put_cloudwatch_percentages(cw_client,100,100)

