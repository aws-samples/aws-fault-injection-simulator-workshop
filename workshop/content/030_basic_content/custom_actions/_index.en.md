+++
title = "Custom_actions"
date =  2021-04-14T17:24:06-06:00
weight = 100
+++

{{% notice warning %}}
Not sure if we should do this at all because this subverts experiment teardown on stop/failure.
{{% /notice %}}

Currently truly custom actions aren't possible - no lambda bindings. It would be possible to work around this through SSM custom documents which in turn could run custom actions.