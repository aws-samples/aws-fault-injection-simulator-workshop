---
title: "Tags: update vs. create"
weight: 30
services: false
draft: false
---

{{% notice note %}}
This section is aimed at large, distributed, and _extremely_ security conscious teams. If that's not a high concern to you, feel free to skip this section.
{{% /notice %}}

As we saw in the previous secion, tags can be used as part of access control policies. Because tags and experiment templates are managed by independent services it is possible to atomically _create_ an experiment template with associated tags but it is not possible to atomically _update_ tags and experiment template content.

To enable update workflows, FIS provides separate API calls for tagging resources ([**CLI**](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/fis/tag-resource.html) / [**API**](https://docs.aws.amazon.com/fis/latest/APIReference/API_TagResource.html)) and for updating template content ([**CLI**](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/fis/update-experiment-template.html) / [**API**](https://docs.aws.amazon.com/fis/latest/APIReference/API_UpdateExperimentTemplate.html)).

While this provides you with a clear choice of update paths, e.g.:

* **update template _then_ update tag** - potential impact changes _before_ access controls change

* **update tag _then_ update temple** - access controls change _before_ potential impact changes

Since the FIS experiment template could be invoked in between the two update steps it is possible that an update process could result in FIS experiments being performed with an unexpected combination of template content and tags.

If you wish to avoid this and find it acceptable for an FIS experiment invocation to fail during an update we suggest implementing a change as:

1. update tags in a way that prevents all execution of the template
2. update template content
3. update tags to desired target state


