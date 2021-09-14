---
title: "Databases"
weight: 50
services: true
---

In this section we will cover working with databases. For this setup we are adding Amazon Relational Database Service (RDS) MySQL and Amazon Aurora (Aurora) for MySQL to our test architecture:

{{< img "ASG-RDS-with-user.png" "Image of architecture to be injected with chaos" >}}

Both RDS MySQL and Aurora for MySQL provide MySQL databases but they are different products. RDS MySQL is a managed service based on stock MySQL while Aurora is a custom built MySQL and PostgreSQL-compatible relational database with better performance and reliability.

Since these are different products they have slightly different failover patterns. They also use slightly different naming conventions:

* For RDS MySQL your dashboard will show "Instances" which may have "Replicas" attached for failover.
* For Aurora MySQL your dashboard will show "Clusters" with "Writers" and "Readers". 

For this workshop we are using a similar configuration that replicates data across two Availability Zones (AZs) for resilience.
