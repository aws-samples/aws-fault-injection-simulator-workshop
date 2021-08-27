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
  * should use the `ref` shortcode for internal referencdes
  * should be based on directory names and thus exclude the leading 2 letter language label rendered in the URL
  * should not have trailing `/` characters
  * examples:
    * Reference `/030_region_selection/_index.en.md` as `[Good]({{< ref "030_region_selection" >}}`
  * workaround for directories not following page bundle format:
    * Reference non-conformant file `/020_starting_workshop/020_aws_event/portal.md` from sibling `/020_starting_workshop/010_self_paced/_index.en.md` as `[Avoid this]({{< ref "../020_aws_event/portal" >}}`

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

Many workshops focus on "click here", replicating a lot procedural instructions. We want to focus on learning. As such we suggest referring back to previous sections for purely procedural instructions. E.g. the [RDS/General template setup](https://chaos-engineering.workshop.aws/en/030_basic_content/050_databases/010_rds_database_reboot.html#general-template-setup) summarizes the desired settings and refers back to the general setup instructions if youe need a refresher.

## Formatting guidelines

We are currently developing these:

* References to other sections should be bolded `[**Section Name**]({{< ref ... >}})`
* Strings that are entered into the UI should be enclosed in backticks, e.g.  `\`Name\`` to render as `Name`
* 