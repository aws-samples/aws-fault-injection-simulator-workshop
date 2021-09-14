---
title: "DevOps Guru"
chapter: false
weight: 10
services: true
---

{{% notice warning %}}
This section requires that you followed the [**setup instructions**]({{< ref "/020_starting_workshop/060_devops_guru" >}}) at the beginning of the workshop and allowed enough time for Amazon DevOps Guru to establish a baseline. This section also presumes that you followed the load generating steps in the **Synthetic user experience** section.
{{% /notice %}}

## Dashboard overview

Navigate to the [DevOps Guru console](https://console.aws.amazon.com/devops-guru/home?#/dashboard). Once enough time has passed for DevOps Guru to generate insights you should see a dashboard similar to this:

{{< img "dashboard.en.png" "DevOps Guru dashboard" >}}

## Reactive insights

Select "Insights" on the left and explore the reactive insights generated from our fault injection activities. You should see an event relating to "Application ELB" (depending on the exact order of events your dashboard may vary slightly):

{{< img "reactive-insights-1.en.png" "Reactive insights" >}}

## Visualizing anomalies 

Selecting the event exposes more detailed information. The "Aggregated metrics" view will show timelines of different anomalous events that happened during the overall anomaly window: 

{{< img "metrics-aggregate-1.en.png" "Anomalies aggregate metrics view part 1" >}}

Note that there may be multiple additional pages for additional events:

{{< img "metrics-aggregate-2.en.png" "Anomalies aggregate metrics view part 2" >}}

Examining the example above we see that during the event 

* an unusually high number of connections were made - by our external load testing tool, 
* the high number of connections led to a high number of overall requests on the load balancer,
* the high number of connections led to a high number of connections to each target,
* the response time for the servers associated with the target increased substantially.

In addition to the expected direct impact of more connections, we also see unusual responses being sent:

* the number of HTTP 5xx errors increased at the load balancer,
* specifically the number of [**HTTP 502**](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/502) error increased at the load balancer,
* the number of HTTP 5xx errors originated at the load balancer target, i.e. our web servers.

Switching to the "Graphed Anomalies" view shows the more detailed time data for each anomalous metric:

{{< img "metrics-graphed-1.en.png" "Anomalies graphed metrics view" >}}

Note that in this view data outside the anomaly window are set to zero to allow focusing on the relevant details during the outage.

## Contextualizing with infrastructure events

In our case the anomalies arose from external load but frequently anomalies are caused by changes to code or infrastructure configuration. To help you diagnose this, DevOps Guru provides visibility into deployment and infrastructure changes associated with the anomaly. These events can be visualized in a timeline view (you can get details by clicking on the dots):

{{< img "infra-timeline.en.png" "Infrastructure changes timeline view" >}}

or in table format:

{{< img "infra-table.en.png" "Infrastructure changes table view" >}}

From the table format we can see that about 2h before the anomaly some changes were made to the stack configuration and deployed code. We can also see that around the time of the event instances were added to the load balancer in response to the increased load, and subsequently removed from the load balancer due to the external event subsiding.

## Recommendations for improvement

Finally DevOps Guru provides "Recommendations", links to relevant articles to help troubleshoot issues and improve overall system performance:

{{< img "recommendations.en.png" "Improvement recommendations" >}}

## Further reading

To learn more about DevOps Guru, see the [**documentation**](https://docs.aws.amazon.com/devops-guru/latest/userguide/welcome.html), and explore using [**DevOps guru on serverless infrastructure**](https://aws.amazon.com/blogs/devops/gaining-operational-insights-with-aiops-using-amazon-devops-guru/) as well as [**larger deployment strategies**](https://aws.amazon.com/blogs/devops/configure-devops-guru-multiple-accounts-regions-using-cfn-stacksets/).
