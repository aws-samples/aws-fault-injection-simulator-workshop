---
title: "Create a Workspace"
chapter: false
weight: 40
services: true
---

{{% notice info %}}
A list of supported browsers for AWS Cloud9 (Cloud9) is found [here]( https://docs.aws.amazon.com/cloud9/latest/user-guide/browsers.html).
{{% /notice %}}

{{% notice tip %}}
Ad blockers, javascript disablers, and tracking blockers should be disabled for the Cloud9 domain, or connecting to the workspace might be impacted. Cloud9 requires third-party-cookies. You can whitelist specific domains by following [**these instructions**]( https://docs.aws.amazon.com/cloud9/latest/user-guide/troubleshooting.html#troubleshooting-env-loading).
{{% /notice %}}

### Launch Cloud9 in the region selected previously

Using the region selected in [**Region Selection**]({{< ref "030_region_selection" >}}), navigate to the [**Cloud9 console**](https://console.aws.amazon.com/cloud9).

- Select **Create environment**
- Name it `fisworkshop` and select **Next step**.
- Since we only need to access our Cloud9 environment via web browser, please select the **Create a new no-ingress EC2 instance for environment (access via Systems Manager)** under the Environment Type.
- Choose `t3.small` for instance type, go through the wizard with the default values. Finally select **Create environment**

When it comes up, customize the environment by:

- Closing the **Welcome tab**
{{< img "images/020_starting_workshop/cloud9-1.png" "Closing the welcome tab" >}}
- Opening a new **Terminal** tab in the main work area
{{< img "images/020_starting_workshop/cloud9-2.png" "Opening new terminal tab" >}}
- Closing the lower work area
{{< img "images/020_starting_workshop/cloud9-3.png" "Closing lower work panel" >}}

Your workspace should now look like this
{{< img "images/020_starting_workshop/cloud9-4.png" "Cloud9 workspace" >}}

### Increase the disk size on the Cloud9 instance

{{% notice info %}}
Some commands in this workshop require more than the default disk allocation on a Cloud9 workspace. The following command adds more disk space to the root volume of the Amazon EC2 (EC2) instance that Cloud9 runs on. 
{{% /notice %}}

Copy/Paste the following code in your Cloud9 terminal (you can paste the whole block at once).  
Once the command completes, we reboot the instance and it could take a minute or two for the Integrated Development Environment (IDE) to come back online.

```bash
# Ensure we have newest boto3 installed
pip3 install --user --upgrade boto3

# Identify instance ID of the Cloud9 environment
export instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# Use API to identify attached volume and increase size
python -c "import boto3
import os
from botocore.exceptions import ClientError 
ec2 = boto3.client('ec2')
volume_info = ec2.describe_volumes(
    Filters=[
        {
            'Name': 'attachment.instance-id',
            'Values': [
                os.getenv('instance_id')
            ]
        }
    ]
)
volume_id = volume_info['Volumes'][0]['VolumeId']
try:
    resize = ec2.modify_volume(    
            VolumeId=volume_id,    
            Size=30
    )
    print(resize)
except ClientError as e:
    if e.response['Error']['Code'] == 'InvalidParameterValue':
        print('ERROR MESSAGE: {}'.format(e))"

# Reboot - on restart the cloud-init will adjust FS size
if [ $? -eq 0 ]; then
    sudo reboot
fi
```

### Update tools and dependencies

{{% notice info %}}
The instructions in this workshop assume you are using a bash shell in a linux-like environment. They also rely on a number of tools. Follow these instructions to install the required tools in an AWS Cloud9 workspace:
{{% /notice %}}

Copy/Paste the following code in your Cloud9 terminal (you can paste the whole block at once).

```bash
# Update to the latest stable release of npm and nodejs.
nvm install stable 

# Install typescript
npm install -g typescript

# Install CDK
npm install -g aws-cdk

# Install the jq tool
sudo yum install jq -y
```
