---
title: "Create a Workspace"
chapter: false
weight: 14
---

{{% notice warning %}}
The Cloud9 workspace should be built by an IAM user with Administrator privileges,
not the root account user. Please ensure you are logged in as an IAM user, not the root
account user.
{{% /notice %}}

{{% notice info %}}
A list of supported browsers for AWS Cloud9 is found [here]( https://docs.aws.amazon.com/cloud9/latest/user-guide/browsers.html).
{{% /notice %}}


<!---
{{% notice info %}}
This workshop was designed to run in the **Oregon (us-west-2)** region. **Please don't
run in any other region.** Future versions of this workshop will expand region availability,
and this message will be removed.
{{% /notice %}}
-->

{{% notice tip %}}
Ad blockers, javascript disablers, and tracking blockers should be disabled for
the cloud9 domain, or connecting to the workspace might be impacted.
Cloud9 requires third-party-cookies. You can whitelist the [specific domains]( https://docs.aws.amazon.com/cloud9/latest/user-guide/troubleshooting.html#troubleshooting-env-loading).
{{% /notice %}}

### Launch Cloud9 in your closest region:

Navigate to the Cloud9 console: https://console.aws.amazon.com/cloud9

- Select **Create environment**
- Name it **fisworkshop**, click Next.
- Choose **t3.small** for instance type, take all default values and click **Create environment**

When it comes up, customize the environment by:

- Closing the **Welcome tab**
![c9before](/images/020_starting_workshop/cloud9-1.png)
- Opening a new **terminal** tab in the main work area
![c9newtab](/images/020_starting_workshop/cloud9-2.png)
- Closing the lower work area
![c9newtab](/images/020_starting_workshop/cloud9-3.png)
- Your workspace should now look like this
![c9after](/images/020_starting_workshop/cloud9-4.png)

