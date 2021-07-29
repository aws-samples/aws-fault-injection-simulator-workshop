---
title: "Optional: Setup for DevOps Guru"
chapter: false
weight: 60
---

{{% notice warning %}}
Only complete this section if you are planning to explore the DevOps Guru section at the end of the workshop. If you are planning to explore DevOps Guru in this way please allow sufficient time for DevOps Guru to perform initial resource discovery and baselining. Depending on the number of resources in the account/region you select this may take from 2-24h.
{{% /notice %}}

Navigate to the [DevOps Guru console](https://console.aws.amazon.com/devops-guru/home?#/home) and click select the "Get Started" button:

{{< img "getting-started.en.png" >}}

For "Amazon DevOps Guru analysis coverage" select "Choose later" if you will only be exploring as part of this workshop. Otherwise you can choose "Analyze all AWS resources in the current AWS account in this Region" but it may take more time and incur more cost to get started.

{{< img "coverage.en.png" >}}

During this workshop we will not be exploring SNS notifications and thus don't need to specify an SNS topic. 

Select "Enable"

If you set coverage to "Choose later" you should now see an information banner notifying you that you have not yet selected resources:

{{< img "no-resources-warning.en.png" >}}

Select the "Manage analysis coverage" option in the banner or navigate to the [DevOps Guru console](https://console.aws.amazon.com/devops-guru/home?#/home), choose "Settings" and select "Manage" option under "DevOps Guru analysis coverage":

{{< img "manage-coverate.en.png" >}}

Select all the Fis stacks:

{{< img "select-stacks.en.png" >}}

Select "Save".

