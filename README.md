# terraform-aws-ami
This terraform module will deploy a CodeBuild project that will build an AMI and place the AMI ID in an SSM Parameter.

If the Packer repository is not public, this module requires an active CodeStar Connection to the Github repository where the packer definition is stored.

The module supports running on a schedule, with the intent to facilitate routine build and deploy models, ie, build a new AMI weekly to get all of the security and patching updates, and then deploy.

The module will setup execution of the CodeBuild project on any commit to the Git repo that has the Packer configuration in it, on the main branch. This branch is configured via variable, so it’s easy to control which branch would initiate a new build.