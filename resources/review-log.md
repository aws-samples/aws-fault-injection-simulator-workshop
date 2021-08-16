This is a checklist for the items in the [review word document](Workshop Review document.docx) in the same folder. 

The intent of this document is to provide a more git compatible document and to allow tracking partial reviews as the workshop gets larger.

# How to use this document 

* read the [review word document](Workshop Review document.docx) so you understand the sections/topics you’ll need to cover during you review.
* (git) check out the repo 
* create a branch with format `username/branchname`
* update the document as you review the workshop. Make sure that your comments for each entry are on a new line to allow git merging
* use a format of `*` REVIEWER_NAME `-` DATE_YYYY_MM_DD `-` Yes/No `-` OPTIONAL_COMMENTS_ALL_ONE_LINE
* when done (git) add, (git) commit, and (git) push, then navigate to GitHub and submit a pull request
* if you found any substantial issues please also create individual "issues" in GitHub

If for some reason you only have access to the public site reach out to rudpot@amazon.com to provide you with a copy of this document. Send the updated document back to rudpot@amazon.com to commit.

# Review Sections


## Workshop introduction

### Is there an introduction that states what will be covered in the workshop?                                                      

* @rudpot - 2021-07-28 - Yes – in intro section
* @chateauv - 2021-08-13 - Yes – in intro section

### Does the introduction give an expected duration?

* @rudpot - 2021-07-28 - Yes – in intro section
* @chateauv - 2021-08-13 - Yes – in intro section

### Does the introduction state the outcomes? (ie what someone completing the workshop will learn)

* @rudpot - 2021-07-28 - Yes – in intro section
* @chateauv - 2021-08-13 - Yes – in intro section

### Does the introduction describe the target audience?

* @rudpot - 2021-07-28 - Yes – in intro section
* @chateauv - 2021-08-13 - Yes – in intro section

### Does the introduction list or describe any necessary background knowledge? For example, a workshop that deals with databases may need some knowledge of basic SQL commands. A workshop on front-end may require knowledge of Javascript, node.js v14 installed, etc.

* @rudpot - 2021-07-28 - Yes – in intro section
* @chateauv - 2021-08-13 - Yes – in intro section

### Does the introduction warn of any costs that may be incurred by the customer?

* @rudpot - 2021-07-28 - Yes – in intro section
* @chateauv - 2021-08-13 - Yes – in intro section


## Environment setup

### If the workshop supports using a customer’s own account, does the workshop describe how to create pre-requisite infrastructure (eg via a CloudFormation, CDK, SAM template, etc) with instructions on how to deploy it?

* @rudpot - 2021-07-28 - Yes
* @chateauv - 2021-08-16 - Yes

### If the workshop integrates with Event Engine, does the workshop include instructions on how to log in via EE. Similarly, if the workshop supports other systems (Qwiklabs, etc) it should provide login instructions for those.

* @rudpot - 2021-07-28 - Yes – description exists but EE is currently unsupported because there is no reaper for FIS yet and building an EE module is still on our backlog.
* @rudpot - 2021-08-12 - Yes - description exists and it is is now possible to run the workshop in EE but creating an EE blueprint is still on the backlog
* @chateauv - 2021-08-16 - Yes

### If the workshop can only use Event Engine, does the front page clearly state that the workshop can only be used at AWS-run events?
                                                                
* @rudpot - 2021-07-28 - N/A
* @chateauv - 2021-08-16 - N/A

### Does the workshop include steps to set up local prerequisites? For example, an attendee may need to install things like node, python, an SSH client, or a Cloud9 environment, etc.

* @rudpot - 2021-07-28 - Yes - the workshop uses Cloud9 and explains how to configure additional requirements
* @chateauv - 2021-08-16 - Yes - Cloud9 + local tools (AWS CLI, SM plugin, ...)

### If the workshop runs only in specific regions, are these clearly listed?

* @rudpot - 2021-07-28 - Yes
* @chateauv - 2021-08-16 - Yes


## Environment clean-up

### Does the workshop provide instructions on how to clean up resources created during the workshop?

* @rudpot - 2021-07-28 - Yes – with extra work to automate cleanup on backlog
* @rudpot - 2021-08-12 - Yes - Automation scripts also added
* @chateauv - 2021-08-16 - Yes

### Are the instructions at the right level of detail? For example, a 100-level workshop may need to walk a customer through all steps of terminating an EC2 instance. A 400-level workshop may simply tell a user to terminate EC2 instances the user created during the workshop.

* @rudpot - 2021-07-28 - Yes
* @chateauv - 2021-08-16 - Yes

### Are the clean-up steps specific to the resources created in the workshop? Generalisations like “terminate all EC2 instances” could have unintended consequences.

* @rudpot - 2021-07-28 - Yes – on the current assumption that all resources are generated through stacks
* @chateauv - 2021-08-16 - Yes

### Are the steps specific to the user? If more than one person is sharing an AWS account, generalisations like “terminate all EC2 instances” could have unintended consequences.

* @rudpot - 2021-07-28 - Yes – on the current assumption that all resources are generated through stacks
* @rudpot - 2021-08-12 - Yes – additional comments added for optionally created resources
* @chateauv - 2021-08-16 - Yes

### Are deliberately retained resources explained? For example, the workshop may deliberately retain an S3 bucket holding the results of a process.

* @rudpot - 2021-07-28 - Yes
* @chateauv - 2021-08-16 - Yes

### If resources are being retained, is there an explicit comment about costs those resources may incur?

* @rudpot - 2021-07-28 - N/A
* @chateauv - 2021-08-16 - N/A

### If clean-up instructions ask the user to delete a CloudFormation Stack, does this delete all resources in the stack? 

####  CloudFormation stack deletion fail to remove some resources, like non-empty S3 buckets. These could then incur ongoing costs and/or raise possible future security risks.

* @rudpot - 2021-07-28 - TBD
* @chateauv - 2021-08-16 - Updated the stack to destroy DB snapshots on DB removal

#### Often a stack provides a workshop’s starting state, and other resources are then created via the console.

* @rudpot - 2021-07-28 - TBD
* @rudpot - 2021-08-12 - Yes – additional comments added for optionally created resources
* @chateauv - 2021-08-16 - Yes

### Does the workshop reference/link to the clean-up steps in the introduction or setup chapters? If someone cannot complete the workshop, they should still know about the existence of clean-up steps. They should not need to complete the workshop before being told of clean-up steps.	

* @rudpot - 2021-07-28 - Yes
* @chateauv - 2021-08-16 - Yes


## Well-architected workshop infrastructure

### Are resources deployed in multiple availability zones?

* @rudpot - 2021-07-28 - Yes
* @chateauv - 2021-08-16 - Yes

### Will resources scale with demand? For example: are EC2 instances deployed within an ASG?

* @rudpot - 2021-07-28 - Yes
* @chateauv - 2021-08-16 - Yes

### For any resources that are not deployed in a redundant, scalable, cost-efficient manner: Is there a comment that this choice is deliberate?	

* @rudpot - 2021-07-28 - Yes
* @chateauv - 2021-08-16 - Yes


## External links and privacy

### Are images and other single files (CloudFormation templates, individual code files, etc) contained within the workshop structure, either within the specific chapter or under the /static folder. For example, an image should use a format like `![](../static/image.png)` and not `![](https://googleimagesearch.com/?term=penguin)`

* @rudpot - 2021-07-28 - Yes - All resources are contained in the repo. Exact structure to support user experience TBD based on whatever Outfitters provides.
* @rudpot - 2021-08-12 - Yes - Verified that this works in public deployment
* @chateauv - 2021-08-16 - Yes

### Do all images used in this workshop have a CC0 license? 

* @rudpot - 2021-07-28 - TBD - All images used are owned by AWS but no licensing info has been added. Backlog item added for this.

### If the workshop references larger bundles of AWS-owned content (for example Lambda source code, sample data sets, etc), are these stored somewhere central like an Event Engine S3 bucket, or an AWS-owned Github Organization (AWS-Samples etc, see Open Source below)? Resources must not be hosted in individually-owned AWS accounts, individual Github accounts, etc.	

* @rudpot - 2021-07-28 - TBD - All resources are stored in this or other public github repos. Deployment model still TBD based on what outfitters provides.
* @rudpot - 2021-08-12 - Yes - Event outfitters pulls directly from GitHub repo
* @chateauv - 2021-08-16 - Yes

### Do links to any Youtube videos use the Hugo “Youtube” shortcode? (This allows us to enforce privacy-enhanced mode when linking to the content)	

* @rudpot - 2021-07-28 - N/A
* @chateauv - 2021-08-16 - N/A

### Are all included data sets comprised of fake data or open data sets held in places like https://registry.opendata.aws/ (Third party data sets can be referenced in the workshop but should not be included)

* @rudpot - 2021-07-28 - N/A
* @chateauv - 2021-08-16 - N/A

### Is the workshop self-contained? (Will the workshop function/can it be delivered if your personal accounts are lost)

* @rudpot - 2021-07-28 - Yes
* @chateauv - 2021-08-16 - Yes


## Security

### Confirm the content does not reference any confidential information, internal tools, or internal-only jargon. (e.g.; internal Amazon systems, employee information, containment scores, etc)s	

* @rudpot - 2021-07-28 - Yes
* @chateauv - 2021-08-16 - Yes

### If IAM Users or Roles are created, do they have appropriately scoped policies? IAM principals should use AWS-managed policies unless there’s a specific need for a custom policy.	

* @rudpot - 2021-07-28 - Yes – exact scopes still TBD based on EE requirements
* @chateauv - 2021-08-16 - Yes

### Do S3 Buckets restrict public access,  either via S3 Block Public Access or an S3 Bucket Policy?

* @rudpot - 2021-07-28 - N/A
* @chateauv - 2021-08-16 - N/A

### Do EC2 Security Groups restrict access to specific source IPs and ports?

* @rudpot - 2021-07-28 - Yes
* @chateauv - 2021-08-16 - Yes

### Do RDS instances have Public Access disabled?

* @rudpot - 2021-07-28 - Yes
* @chateauv - 2021-08-16 - Yes

### For configurations that don’t adhere to AWS Well-Architected practices, is there a note that explains why this is done, and a recommendation for a best-practice approach?

* @rudpot - 2021-07-28 - N/A
* @chateauv - 2021-08-16 - N/A

### Does sample code (eg Lambda functions) perform only the required actions?

* @rudpot - 2021-07-28 - Yes
* @chateauv - 2021-08-16 - Yes

### Does sample code run using an IAM role that allows only required actions?

* @rudpot - 2021-07-28 - Yes
* @chateauv - 2021-08-16 - Yes

### If attendees are asked to enter information, is this anonymised? Personally Identifiable Information (PII) should be avoided unless strictly necessary (for example testing SES may require the attendees enter a valid email address to receive an email).

* @rudpot - 2021-07-28 - N/A
* @chateauv - 2021-08-16 - N/A


## Source code, sample data, third party sources, and Open Source

### If the workshop includes any AWS-created code (eg Lambda functions) does the code include a license? The MIT-0 license is a good choice for workshop sample code that is not intended for production use.

* @rudpot - 2021-07-28 - No – backlog item added as for images

### Third-party code should be referenced rather than included whenever possible, but when third-party code must be included that code's license must allow for Amazon/AWS usage and the workshop should include attribution. If you’re unsure, contact the Open Source team here: https://w.amazon.com/?Open_Source/Distributions

* @rudpot - 2021-07-28 - Yes

### If AWS-provided code includes any third-party code, are all required attributions are present? For example the CC-BY license allows usage, but requires attribution and indications of any changes.	

* @rudpot - 2021-07-28 - N/A
* @chateauv - 2021-08-16 - N/A

### If the workshop uses or references third-party data sets, does AWS have the right to use those data sets in a workshop scenario? If you’re unsure, flag this and ask Legal via https://legal.amazon.com/sites/AWS-Collab/agreementresources/Sherpa/SitePages/Home.aspx

* @rudpot - 2021-07-28 - N/A
* @chateauv - 2021-08-16 - N/A

### If the workshop references AWS-owned sample code on Github, is the code under an Amazon-owned Github Organization, for example AWS-samples? Personally-owned github repos are not acceptable. For AWS sample code, there’s an expedited process to review and release sample code

* @rudpot - 2021-07-28 - Yes
* @chateauv - 2021-08-16 - Yes


## Content, spelling, and grammar

### Is the information in the workshop factually correct?

* @rudpot - 2021-07-28 - Yes – to the best of our current knowledge
* @chateauv - 2021-08-16 - Yes

### Could you complete all the steps in the workshop without error?

* @chateauv - 2021-08-16 - Yes - except "Experiment (CLI)", "Experiment (CloudFormation)", "Simulating AZ issues" (not tried)

### If you did encounter errors, did the workshop guide help resolve those?	

* @chateauv - 2021-08-16 - Yes

### Is the workshop specific enough in its instructions, without being verbose? This can be dependent on level. For example, a 100-level workshop may need to walk a customer through all steps of launching an EC2 instance. A 400 level workshop may simply tell a user to launch an EC2 instance using an AmazonLinux2 AMI. Note/list any sections that could be improved.	

* @chateauv - 2021-08-16 - Yes

### Are there any sections that would be better described with a diagram or image? Minimize the use of AWS Console screenshots. Frequent changes to the AWS Console mean these become outdated, and then cause confusion.	

* @chateauv - 2021-08-16 - No - Diagrams are provided when needed.

### Does the workshop avoid rhetorical devices that may be unclear to non-native-language speakers? For example “grab a cup of joe while you wait. Most of the time, it’s faster than a rat up a drainpipe”	

* @rudpot - 2021-08-12 - Yes
* @chateauv - 2021-08-16 - Yes


## Accessibility and Inclusion

### Do all images have accurate, descriptive alternate text? The IMG Hugo shortcode allows alternate text to be included.

* @rudpot - 2021-07-28 - No – added backlog item for this
* @rudpot - 2021-08-12 - Yes – converted all images to use shortcode, added alt text, added warning so hugo rendering will alert if an image is missing alt text
* @chateauv - 2021-08-16 - Yes

### Do images avoid red/green elements that could cause issues for people with colorblindness?

* @rudpot - 2021-07-28 - Yes – images use standard console colors
* @chateauv - 2021-08-16 - Yes

### Do videos have (or allow for) subtitles?

* @rudpot - 2021-07-28 - N/A
* @chateauv - 2021-08-16 - N/A

### Does the workshop content adhere to Amazon’s Inclusive Tech Guidelines? e.g.: Do not use terms such as blacklist/whitelist, master/slave, etc. 	

* reviewer - YYYY-MM-DD - TBD


## Internationalization / multi-language

### Are all languages/translations listed in the drop-down on the left-hand menu? Do all language choices link to complete translations of the workshop? The Aws-workshop-template ships with English and French as defaults, to show how multi-language works. Sometimes workshop owners leave the French default pages in place.

* @rudpot - 2021-07-28 - N/A – currently only English is supported
* @rudpot - 2021-08-12 - N/A – source `config.toml` does reference French but publication tools strip this out. Will deal with this when someone submits a translation.


# Additional comments

Space for any additional comments you may have for the workshop author.

* reviewer - YYYY-MM-DD - TBD
