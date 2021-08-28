# Conventions

We will keep adding to this list as the workshop grows. Please review frequently:

## Content directory naming

* content is located in `workshop/content`
* directory names 
  * should use 3 digit prefix to sort content
  * should not contain spaces
  * should use snake case, i.e. all lower case characters with underscores `_` as separators
  * example `030_basic_content/010-baselining/`
* content should use [page bundle](https://gohugo.io/content-management/organization/#page-bundles) conventions
  * directories should contain singe `.md` file named `_index.en.md` (or an appropriate 2-letter language code for translations)
  * directories should not contain additional `.md` files
* images
  * should be located in same directory as `.md` file referencing them (placing them in `static/` will work but is strongly discouraged)
  * should contain a 2-letter language code, e.g. `myimage.en.png`
  * should use the `img` shortcode
  * must have alt text
  * example: `{{< img "create-template-2-targets-1.en.png" "Add FIS target" >}}`

## References

* references
  * should use `[]()` style
* cross references between pages
  * should use the `ref` shortcode for internal referencdes
  * should be based on directory names and thus exclude the leading 2 letter language label rendered in the URL
  * should not have trailing `/` characters
  * examples:
    * Reference `/030_region_selection/_index.en.md` as `[Good]({{< ref "030_region_selection" >}}`
  * workaround for directories not following page bundle format:
    * Reference non-conformant file `/020_starting_workshop/020_aws_event/portal.md` from sibling `/020_starting_workshop/010_self_paced/_index.en.md` as `[Avoid this]({{< ref "../020_aws_event/portal" >}}`
* references to the AWS console
  * should not contain region information
  * may be more specific than the text description to avoid extra navigation if possible
  * example:
    * `https://console.aws.amazon.com/fis/home?#` instead of `https://us-west-2.console.aws.amazon.com/fis/home?region=us-west-2#`
    * `https://console.aws.amazon.com/fis/home?#ExperimentTemplates` instead of `https://console.aws.amazon.com/fis/home?#`


## Overview pages

We want to provide context for learning. As such major sections should provide an overview of the intended learning and should provide archticture diagrams to support visual learning.


## Experiment template section structure

In the experiment and experiment template sections we want to focus on how to work backwards from a hypothesis. As such we suggest following this structure:

```
## Experiment idea
Idea description
* **Given**: our setup for resilience
* **Hypothesis**: breaking component x will have no adverse effect / will have adverse effect quantified below critical threshold
## Experiment setup
## Validation procedure
## Run FIS experiment
### Review results
## Learning and improving
```

## Brevity

* Remove text duplication - Many workshops focus on "click here", replicating a lot procedural instructions. We want to focus on learning. As such we suggest referring back to previous sections for purely procedural instructions. E.g. the [RDS/General template setup](https://chaos-engineering.workshop.aws/en/030_basic_content/050_databases/010_rds_database_reboot.html#general-template-setup) summarizes the desired settings and refers back to the general setup instructions if youe need a refresher.
* Focus on relevant code and configs - There is friction between providing fully functional code while also providing the reader with focus on the relevant aspects of the code. Because this workshop provides an associated GitHub repository for the code we suggest only showing what the reader needs to pay attention to. E.g. in the [First Experiment / Configuring Permissions](https://chaos-engineering.workshop.aws/en/030_basic_content/030_basic_experiment/10-permissions.html) section we show a full IAM policy because we want to reader to deeply study it. In contrast in the [AWS FIS template overview](https://chaos-engineering.workshop.aws/en/030_basic_content/030_basic_experiment/30-experiment-cli.html#template-overview) section we show only the relevant scaffolding items.

## Text formatting guidelines

We are currently developing these:

* References to other sections should be bolded `[**Section Name**]({{< ref ... >}})`
* Verbatim strings from the UI, strings that are entered into the UI, and strings referencing code should be enclosed in backticks, e.g.  `` `Name` `` to render as `Name`
* References to UI tabs should be formatted as `**"Tab name"**` to render as **"Tab name"**
* References to UI burger menu items should be formatted as `**"Menu item"**` to render as **"Menu item"**

## Image formatting guidelines

* obscure any sensitive information such as account numbers
* create visual context. It is tempting to take multiple screen shots zoomed in on relevant sections of the UI but this hides context. Wherever practical take a single screenshot and highlight relevant points in context of the overall UI view.
* ensure that entry fields in images match entry text in description
