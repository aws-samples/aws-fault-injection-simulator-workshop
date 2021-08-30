# Local setup for developing and contributing

To contribute pull requests you will need to:

* install pre-requisite software
* [fork](https://docs.github.com/en/get-started/quickstart/fork-a-repo) this repository
* make and commit changes to your fork
* [create a pull request with your changes](https://docs.github.com/en/github/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork)

## Pre-requisites

You will need a linux or mac environment, we recommend using [AWS Cloud9](https://aws.amazon.com/cloud9/) if you don't already have an environment, with the following tools installed:

* `bash` 
* `jq`
* [`git`](https://git-scm.com/downloads)
* [`node` and `npm`](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm)
* [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
* [AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html)
* [AWS CDK](https://docs.aws.amazon.com/cdk/latest/guide/getting_started.html#getting_started_install)
* [Hugo](https://gohugo.io/getting-started/installing/)

## Repo structure

Use this guide to determine where to find or place assets:

```bash
.
├── metadata.yml                      <-- Metadata file with descriptive information about the workshop
├── README.md                         <-- The main readme file
├── LOCAL.md                          <-- This instructions file
├── deck                              <-- Directory for presentation deck(s) 
├── resources                         <-- Directory for workshop resources 
│   ├── code                          <-- Directory for workshop modules code
│   ├── policies                      <-- Directory for workshop modules IAM Roles and Policies
│   ├── templates                     <-- Directory for workshop modules CloudFormation templates
|   └── review-log.md                 <-- Workshop Review document (git friendly version)
└── workshop                          
    ├── config.toml                   <-- Hugo configuration file for the workshop website
    └── content                       <-- Markdown files for pages/steps in workshop
    └── static                        <-- Any static assets to be hosted alongside the workshop (ie. images, scripts, documents, etc)
    └── themes                        <-- AWS Style Hugo Theme (Do not edit!)
```

## Local website rendering

To preview the workshop clone this repo, and serve it locally with [Hugo](https://gohugo.io/):

```bash
cd aws-fault-injection-simulator-workshop
# This will exclude draft content. Add -D flag for hugo to render draft content
cd workshop
hugo server -D
```

and browse to http://localhost:1313. Note the use of the `-D` flag. This will render pages in `draft` mode that would otherwise be hidden. The theme will highlight pages in draft mode to remind you to update them before your pull request.

## Upgrading your development environment

If you keep working on this for an extended period of time you may need to update your development environment.

### Using/upgrading Cloud9 environment

Cloud9 already comes with nvm. 

```bash
nvm install stable
npm install -g typescript
npm install -g aws-cdk
```

### Upgrading local environment

We recommend using nvm to manage your node environments. Install nvm using [brew](https://brew.sh/).

```bash
# Follow the instructions after running brew install to create .nvm dir and add PATH variables
brew install nvm 
# Reload configs or restart shell
nvm install stable
npm install -g typescript
npm install -g aws-cdk
```

### Upgrading NPM dependencies locally

The workshop extensively uses node modules as part of CDK. To avoid security vulnerabilities we have automation that will regularly upgrade package versions in the main repo. To keep your local NPM dependencies updated without needing to continously merge in the upstream changes use the [npm-check-updates](https://www.npmjs.com/package/npm-check-updates) utility. See `.github/workflows/npmfixer.yaml` for some hints on how to do this.

*Note* All versions may not be compatible with each other. You may have to manually set versions in package.json. For example, CDK@1.115.0 is incompatible with jest@27.0.6.

### Deploying to AWS

Currently we only support using a deploy script against an existing AWS account. 

**Note:** The deploy script does not specify a deploy profile. Following AWS CLI conventions it will use the default profile and region. If you wish to use a different profile/region, set the AWS_PROFILE and AWS_DEFAULT_REGION environment variables.

**Note:** RDS and EKS deployments take time and don't need to be serialized. To speed up deployments the `deploy-parallel.sh` script will run as much as possible in parallel and write output to files named `deploy-output.SECTION.txt`. If you want serialized deployments, e.g. for debugging, use the `deploy.sh` script instead.

```
cd aws-fault-injection-simulator-workshop

cd resources/templates
./deploy-parallel.sh
```

If you need to make updates to existing stacks, the deploy script can be with the `update` flag:

```
./deploy-parallel.sh update
```

This workshop was built from a template. The original README for the template is [here](README-template.md)

