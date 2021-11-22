---
title: "Tags: update vs. create"
weight: 30
services: false
draft: false
---

{{% notice note %}}
This section is aimed at large, distributed, and _extremely_ security conscious teams. If that's not a high concern to you, feel free to skip this section.
{{% /notice %}}

As we saw in the previous section, tags can be used as part of access control policies. To enable update workflows, FIS provides separate API calls for tagging resources ([**CLI**](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/fis/tag-resource.html) / [**API**](https://docs.aws.amazon.com/fis/latest/APIReference/API_TagResource.html)) and for updating template content ([**CLI**](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/fis/update-experiment-template.html) / [**API**](https://docs.aws.amazon.com/fis/latest/APIReference/API_UpdateExperimentTemplate.html)).


Because tags and experiment templates are managed by independent services it is not possible to atomically update tags _and_ experiment template content _at the same time_.

If you have use cases where you need prevent template execution while performing updates on both tags and template content, we recommend that you update the templates and tags with the following steps:

1. Update tags to prevent all execution of the template. The exact approach will depend on the relevant IAM policies in your account.
2. Update template content.
3. Update tags to desired target state.

