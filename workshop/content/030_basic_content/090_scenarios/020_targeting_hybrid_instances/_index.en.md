---
title: "Target on-prem instances"
weight: 20
draft: true
services: false
---

Target on-prem instances via combination of ssm action (select) / run-command (execute on target) as per question from Mengxin Zhu

```json
Role
```

```bash
aws ssm create-document \
    --name ${SSM_DOCUMENT_NAME} \
    --document-format YAML \
    --document-type Automation \
    --content file://hybrid-target.yaml 

aws ssm update-document \
    --name ${SSM_DOCUMENT_NAME} \
    --document-format YAML \
    --content file://hybrid-target.yaml \
    --document-version '$LATEST'

```

```
[ { "Key": "PingStatus", "Values": [ "Online" ] } ]
```