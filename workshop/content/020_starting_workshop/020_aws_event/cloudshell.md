---
title: "Configure AWS CloudShell"
chapter: false
weight: 20
services: true
---

While it is possible to do this workshop from your desktop, the instructions in this workshop will assume that you are using AWS CloudShell (AWS events) or AWS Cloud9 (in your own account). 

To open CloudShell, navigate to the [AWS console](https://console.aws.amazon.com/console/home) and either search for "CloudShell" or click on the CloudShell icon in the menu bar:

{{< img "start-cloudshell.png" "Start CloudShell" >}}

Once the CloudShell terminal opens, we need to check out the GitHub repository. Paste the following into your CloudShell:

```bash
mkdir -p ~/environment
cd ~/environment
git clone https://github.com/aws-samples/aws-fault-injection-simulator-workshop.git
```

If this is this first time you are using CloudShell you may receive a dialog box asking to confirm a multi-line paste:

{{< img "cloudshell-safe-paste.png" "Confirm CloudShell multi-line paste" >}}

Optionally uncheck the "Ask before pasting multiline code" checkbox. Then select "Paste".

You should see a git clone like this:

{{< img "clone-git-repo.png" "GitHub clone" >}}


### Update tools and dependencies

{{% notice info %}}
The instructions in this workshop assume you are using a bash shell in a linux-like environment. They also rely on a number of tools. Follow these instructions to install the required tools in CloudShell:
{{% /notice %}}

Copy/Paste the following code in your CloudShell terminal (you can paste the whole block at once).

```bash
# Update to the latest stable release of npm and nodejs.
sudo npm install -g stable 

# Install typescript
sudo npm install -g typescript

# Install CDK
sudo npm install -g aws-cdk

# Install the jq tool
sudo yum install jq -y

```
