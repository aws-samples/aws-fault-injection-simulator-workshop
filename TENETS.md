# Tenets

These are our tenets. We are open to feedback if you know better ones:

* all experiments have to be supported by code to create the required infrastructure. The code should be stored in `templates/code/` and can be initially delivered using common AWS Infrastructure as Code (IaC) methods.
  * if using AWS CDK use Typescript as language.
  * if using AWS CloudFormation avoid using nested stacks.
  * IaC code should provide a least-privileges IAM policy for the permissions needed to create the infrastructure.
  * any IAM policies created by IaC code or used in the workshop should adhere to a principle of least privilege.
* to support delivery in labs and at large scale events the (IaC) definition should provide a path to generating a cloudformation template that does not require parameters.
* we do not allow pushes directly to main and require pull-requests.
* branches should be named `CONTRIBUTOR/TOPIC`, e.g. `rudpot/fix-wording`.
* branches should be closed after a pull request is merged.
