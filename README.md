# AWS Fault Injection Simulator workshop


Work in progress. You can checkout/fork and make pull requests or send any suggestions for features to rudpot@amazon.com.


To preview the workshop clone this repo, and serve it locally with [hugo](https://gohugo.io/):

```

cd aws-fault-injection-simulator-workshop

cd workshp
hugo server
```

and browse to http://localhost:1313


This workshop was built from a template. The original README for the template is [here](README-template.md)

## Charter / decisions

Like tenets all of these are up for debate

* ultimate deliverable has to work with EE and thus be CFN code but we are ok starting with CDK. If you want to use CDK for any part please use TS so we can easily integrate
* backlog is currently under [issues, labeled with "backlog"](resources/templates/)
* you can't push straight to main, we want pull-requests. If reviews become a bottleneck we can revisit this

