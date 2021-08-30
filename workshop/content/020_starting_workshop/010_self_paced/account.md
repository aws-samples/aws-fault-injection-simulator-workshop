---
title: "Create an AWS account"
chapter: false
weight: 10
---

{{% notice warning %}}
Your account must have the ability to create new IAM roles and scope other IAM permissions.
{{% /notice %}}

1. If you don't already have an AWS account with **"Administrator"** access: [**Create
an AWS account by clicking here**](https://portal.aws.amazon.com/billing/signup).

1. Once you have an AWS account, ensure you are following the remaining workshop steps as an IAM user with administrator access to the AWS account:
[**Create a new IAM user to use for the workshop**](https://console.aws.amazon.com/iam/home?#/users$new)

1. Enter the user details:
{{< img "images/020_starting_workshop/iam-1-create-user.png" "Enter the user details" >}}

1. Attach the **"AdministratorAccess"** IAM Policy:
{{< img "images/020_starting_workshop/iam-2-attach-policy.png" "Attach IAM policy to new user" >}}

1. Select **"Create user"**:
{{< img "images/020_starting_workshop/iam-3-create-user.png" "Confirm user creation" >}}

1. Take note of the sign-in URL and save:
{{< img "images/020_starting_workshop/iam-4-save-url.png" "Login url for new account" >}}

1. Sign out of your current AWS Console session: on the top menu, select your login and select **"Sign out"**
{{< img "images/020_starting_workshop/iam-5-sign-out.png" "Login url for new account" >}}

1. Sign in to a new AWS Console session by using the sign-in URL saved and the newly created user credentials.

1. Once you have completed the steps above, you can head straight to the [**Region Selection**]({{< ref "030_region_selection" >}}).