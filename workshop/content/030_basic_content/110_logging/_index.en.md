---
title: "Logging"
chapter: false
weight: 100
services: true
---

Fault Injection service generate logs in CloudWatch, these logs presist for 30 days, but one missing aspect of these logs is the experment template itself, if we change the template at any point after the initial run we lose what was tested at that point in time.
to solve this, we can create a lambda that gets invoked by eventbridge when an experment gets executed, the lambda will pull the log and the current template combine the two and save them in a specified S3 bucket for long term retention.