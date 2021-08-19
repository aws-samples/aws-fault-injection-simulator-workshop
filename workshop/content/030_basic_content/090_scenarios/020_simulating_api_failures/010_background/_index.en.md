+++
title = "Background"
weight = 10
+++

AWS API errors can and do experience failures.  As you build applications that itegrate with these APIs, it is important to consider the possibility of failure in order to build a better customer experience into your applications.

In the following sections we will look at a couple different API failure scenarios and how you can mitigate risk of impact using a serverless application.  We will be using the Amazon Fault Inject Service to degrade our application ability to interact with the EC2 api and also discuss some practical steps you can take to reduce the impact.  