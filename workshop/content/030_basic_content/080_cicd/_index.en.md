---
title: "Recurrent Experiments - CI/CD"
weight: 80
services: true
---

So far we have discussed iterating through a cycle of: 

* establish baseline performance data 
* develop _new_ hypothesis
* run experiment
* verify hypothesis
* improve based on findings

In this section we will address use cases in which we want test and _existing_ hypothesis multiple times. Common examples for this are:

* ensure the system remains resilient after changes (CI/CD)
* ensure detection and recovery continue to work (Disaster Recovery)

## "Experiment" or "Test"?

A deep dive into testing terminology is outside the scope of this workshop but for readers familiar with the field we want to point out some analogies and provide some considerations:

### Human-led processes

The hypothesis based cycle we've discussed up to this point is very similar to "Exploratory Testing" and "Acceptance Testing" in the sense that it steps away from purely validating that something "works as intended". Just like "Exploratory Testing" and "Acceptance Testing", the human-led fault injection process should allow for human observation to adjust the "intent".

### Machine-led processes

Automating fault injection based on prior validation of a hypothesis is analogous to the wide range automated and recurrent tests such as:

* unit tests
* regression tests
* integration tests
* load tests

Just like for other tests, it is important to consider the scope and _duration_ of recurrent fault injection experiments. Because fault injection experiments generally expose issues across a large number of linked systems they will typically require extended run times to ensure sufficient data collection. In order to not slow down developers they should be run in later stages of CI/CD pipelines.

## Architecture

For demonstration purposes we have made the following choices but there are many other ways to build valuable automation:

* **CI/CD** - We focus on running experiments in a CI/CD pipeline with the argument that it's easy to slow down a pipeline to run only once a year but hard to speed up a manual process to run multiple times every day.

* **One repo** - We use a single repository to host the definition of the pipeline, the infrastructure, and fault injection template. We do this to show how one would co-version all components of a system but whether this is a good idea for you depends on your governance processes and each of the parts could easily be independent. 

The setup looks like this:

{{< img "Continuous-Stress.png" "Continuous stress architecture" >}}

In the next section we will:

* create a code repository and a pipeline using AWS CDK
* trigger the pipeline to instantiate sample infrastructure
* trigger the pipeline to update infrastructure and perform fault injection 
