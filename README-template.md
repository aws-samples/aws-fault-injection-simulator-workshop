# Aws-workshop-template

This repo provides the templating to make it easy to create a workshop similar to those available at [net-immersionday.workshop.aws](https://net-immersionday.workshop.aws/), and [eksworkshop.com](https://eksworkshop.com/)


## 2021 update on standardizing workshop creation, hosting, and discovery:

All AWS Workshops should use this template, and should be published using the workshops.aws publishing system. For more details, see here: [https://w.amazon.com/bin/view/AWS/Teams/SA/Customer_Engagements/workshops](https://w.amazon.com/bin/view/AWS/Teams/SA/Customer_Engagements/workshops). In summary:

* Workshops are hosted under *.workshop.aws domains. We will provide you a CodeCommit repo and provide an automated build and publication pipeline.
* Prior to 2021, workshops went through the Tech Content 2.0 process. In 2021 this is changing to use a new **Workshop Review** process. Once you've written your content, get someone to review your workshop with the Workshop Review document (included in this repo).
* Submit a [SIM ticket](https://issues.amazon.com/issues/create?template=fe213816-f990-466a-962c-6f1ffc895167) to onboard your workshop to under *.workshop.aws.
* This will also add your workshop to the catalog at [https://internal.workshops.aws](https://internal.workshops.aws) and [https://www.workshops.aws](https://www.workshops.aws)

## Security and regulatory compliance
Historically, SAs and others have created and hosted workshops in their own AWS accounts, Github, S3 buckets, Word documents, and other places. This makes it hard to discover workshops, hard to find the owner to collaborate on improvements, and hard to ensure workshops meet our quality and compliance bar. The SA Customer Engagements team has created the workshop.aws system to host workshops under the workshop.aws domain. By using this template and the workshop.aws publishing system, you can ensure your workshop is secure, discoverable, high quality, and does not expose Amazon to legal or policy concerns. (all issues we have seen with self-published workshops). Later in 2021 the workshop publication process will merge into Event Engine.


## Repo structure

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

## What's Included

This project includes the following folders:

* `workshop`: This is the core workshop folder. This is generated as HTML and hosted for presentation for customers.
* `Workshop Review document`: This is the current Workshop Review document. All workshops need to be reviewed by someone other than the author, before they can be published.
* `deck`: **UNUSED RIGHT NOW** Future location to store your presentation materials. For now, you should store them centrally in KnowledgeMine. 
* `resources`:  **UNUSED RIGHT NOW** Store any example code, IAM policies, or Cloudformation templates needed by your workshop here.


## Requirements

1. [Clone this repository](https://help.github.com/articles/fork-a-repo/).
2. Install[Hugo](https://gohugo.io/overview/quickstart/) on your laptop. As of 1 Aug 2020, the workshop.aws build process uses [Hugo 0.74.3](https://github.com/gohugoio/hugo/releases/tag/v0.74.3) so you should probably use that version.


# Getting Started

## Navigate to the `workshop` directory

All command line directions in this documentation assume you are in the `workshop` directory. Navigate there now, if you aren't there already.

```bash
cd Aws-workshop-template/workshop
```

## Launching the website locally, and follow the tutorial

Run the following command to get Hugo to build the template and run it locally using its in-built server:

```bash
hugo server
```

Go to `http://localhost:1313`

You should notice three things:

1. You have a left-side **Intro** menu, containing menu items that match the directory structure in the "workshop" directory.
2. The home page explains how to customize it by following the instructions.
3. When you run `hugo server`, when the contents of the files change, the page automatically refreshes with the changes. Neat!


## Things to be aware of:

* Remove the links to "Event Outfitters" from the bottom of the front page before you publish your workshop.
* Update the config.toml with your workshop name - the default is at the top, and also under the section [Languages.en]
```
title = "My AWS Workshop"
```
* The template includes two sample languages, French and English (eg "_index.en.md" and "_index.fr.md"). Remove the example French language selection from the **config.toml** unless you plan to provide a French-language version of your content. Delete the following lines:
```
[Languages.fr]
title = "Mon atelier AWS"
weight = 2
languageName = "Français"
```