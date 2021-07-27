# AWS Fault Injection Simulator workshop


Work in progress. You can checkout/fork and make pull requests or send any suggestions for features to rudpot@amazon.com.

## Local website

To preview the workshop clone this repo, and serve it locally with [hugo](https://gohugo.io/):

```
cd aws-fault-injection-simulator-workshop

cd workshop
hugo server
```

and browse to http://localhost:1313

## Instantiating workshop resources

Currently this is a hodgepodge of source types (cdk, SAM, CFN) which will all eventually need to be merged into plain CFN for EE use. For now to instantiate the resources on a Mac/Linux box with installed `bash`, `jq`, `AWS CLI`, `SAM CLI` and `CDK CLI`:

### Tooling

- CDK @ 1.115.0
- npm @ 7.19.1
- node @ 16.5.0

*If you are upgrading your tooling to new versions you will need to delete the node_modules/ directory in each CDK project*

#### Upgrading Cloud9 environment

Cloud9 already comes with nvm. 

```bash
nvm install stable
npm install -g typescript
npm install -g aws-cdk
```

#### Upgrading local environment

We recommend using nvm to manage your node environments. Install nvm using [brew](https://brew.sh/).

```bash
# Follow the instructions after running brew install to create .nvm dir and add PATH variables
brew install nvm 
# Reload configs or restart shell
nvm install stable
npm install -g typescript
npm install -g aws-cdk
```

#### Upgrading NPM dependencies 

To keep your NPM dependencies updated in the future use the [npm-check-updates](https://www.npmjs.com/package/npm-check-updates_) utility.

*Note* All versions may not be compatible with each other. You may have to manually set versions in package.json. For example, CDK@1.115.0 is incompatible with jest@27.0.6.

***The deploy script uses the default profile set for AWS CLI. Modify lines 26 and 27 to use a custom profile***

```
cd aws-fault-injection-simulator-workshop

cd resources/templates
./deploy.sh
```

If you need to make updates the deploy script can be called as

```
./deploy.sh update
```

This workshop was built from a template. The original README for the template is [here](README-template.md)

## Repo structure

Use this guide to determine where to place assets.

```bash
.
├── metadata.yml                      <-- Metadata file with descriptive information about the workshop
├── README.md                         <-- This instructions file
├── deck                              <-- Directory for presentation deck (Future use)
├── resources                         <-- Directory for workshop resources (Future use)
│   ├── code                          <-- Directory for workshop modules code
│   ├── policies                      <-- Directory for workshop modules IAM Roles and Policies
│   ├── templates                     <-- Directory for workshop modules CloudFormation templates
    └── Workshop Review document.doc  <-- Workshop Review document to be completed before your workshop is published
└── workshop                          
    ├── config.toml                   <-- Hugo configuration file for the workshop website
    └── content                       <-- Markdown files for pages/steps in workshop
    └── static                        <-- Any static assets to be hosted alongside the workshop (ie. images, scripts, documents, etc)
    └── themes                        <-- AWS Style Hugo Theme (Do not edit!)
```

### Design Conventions

We are using the following convetions in this workshop:
- No upper case characters and/or spaces in directory names. Use snake case i.e. underscores and all lower case characters
- Use 3 digit prefix to sort content

## Charter / decisions

Like tenets all of these are up for debate

* ultimate deliverable has to work with EE and thus be CFN code but we are ok starting with CDK. If you want to use CDK for any part please use TS so we can easily integrate
* backlog is currently under [issues, labeled with "backlog"](resources/templates/)
* you can't push straight to main, we want pull-requests. If reviews become a bottleneck we can revisit this
* suggested structure for each section so we don't just focus on "click here":
  ```
  ## Experiment idea
  Idea
  * **Given**: our setup for resilience
  * **Hypothesis**: breaking component x will have no adverse effect / will have adverse effect quantified below critical threshold
  ## Experiment setup
  ## Validation procedure
  ## Run FIS experiment
  ### Review results
  ## Learning and improving
  ```