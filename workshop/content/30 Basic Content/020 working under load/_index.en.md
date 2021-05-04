+++
title = "Synthetic user experience"
weight = 2
+++

To gain insights from our fault-injection tests we want to be able to correlate the user experience with the sysops view we've gained in the previous section. In production we could instrument the clients to send telemetry back to us but in non-production we don't usually have sufficient load to do this - and _you_ probably have better things to do than sit there clicking reload on a browser page while your experiment is running.

{{% notice warning %}}
Still need to figure out how to get my goat-redux included in an EE template so this is work to do and the description is how it "works on my desktop" right now.
{{% /notice %}}

We want to achieve two distinct goals: we want to generate enough load to capture a broad spectrum of user experiences and we want to collect the resulting telemetry so we can display it in our dashboard. For this we use https://github.com/rudpot/private-goad-redux (this is currently private, ask me for access) which deploys a lambda function that can be called for a variety of load scenarios.



To do this we need to sim


Our dashboard from the previous section shows us a sysops view of reality but our fault injection tests we 


Section outcomes:

* understanding system behavior BEFORE hitting it with Load / FIS
  * explore single instance behavior (instance created by workshop setup template)
  * validate website serving
  * view logs 
    * on instance (/var/log/nginx/)
    * in cloudwatch (basic dashboard created by workshop setup template)
* understanding system behavior under external load 
  * run goad against static page and see metrics - essentially no impact
  * run goad against computed page and see metrics - seeing error messages

{{< img "dashboard2.en.png" "Image of architecture injected with chaos" >}}
{{< img "dashboard.en.png" "Image of architecture injected with chaos" >}}