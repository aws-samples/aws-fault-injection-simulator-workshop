+++
title = "Simulating API Failures"
weight = 60
+++

Customer workloads often depend on the availability of AWS api endpoints.  Sometimes these endpoints will result in the following errors:

- API Throttling due to service quotas
- Service unavailable 
- Internal Service Errors

In this section we will consider some application patterns you may consider when Amazon Fault Injection Service introduces AWS API Failures in an experiment.  