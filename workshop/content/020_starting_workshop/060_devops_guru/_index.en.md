---
title: "Optional: Setup for Amazon DevOps Guru"
chapter: false
weight: 60
services: true
---

{{% notice warning %}}
Only complete this section if you are planning to explore the Amazon DevOps Guru (DevOps Guru) section at the end of the workshop. If you are planning to explore DevOps Guru in this way please allow sufficient time for DevOps Guru to perform initial resource discovery and baselining. Depending on the number of resources in the account/region you select this may take from 2-24h.
{{% /notice %}}

Navigate to the [**DevOps Guru console**](https://console.aws.amazon.com/devops-guru/home?#/home) and select the **"Get Started"** button:

{{< img "getting-started.en.png" "DevOps Guru console image" >}}

For "Amazon DevOps Guru analysis coverage" select **"Choose later"** if you will only be exploring as part of this workshop. Otherwise you can select "Analyze all AWS resources in the current AWS account in this Region" but it may take more time and incur more cost to get started.

{{< img "coverage.en.png" "Select coverage range">}}

During this workshop we will not be exploring Amazon Simple Notification Service (SNS) notifications and thus don't need to specify an SNS topic. 

Select **"Enable"**.

If you set coverage to "Choose later" you should now see an information banner notifying you that you have not yet selected resources:

{{< img "no-resources-warning.en.png" "Warning banner no resources" >}}

Select the **"Manage analysis coverage"** option in the banner or navigate to the [**DevOps Guru console**](https://console.aws.amazon.com/devops-guru/home?#/home), choose **"Settings"** and select **"Manage"** option under "DevOps Guru analysis coverage":

{{< img "manage-coverage.en.png" "Managing coverage on console" >}}

Select all the stacks with names starting with `Fis`:

{{< img "select-stacks.en.png" "Select FIS stacks" >}}

Select **"Save"**.

