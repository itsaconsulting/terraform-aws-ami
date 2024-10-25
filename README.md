# terraform-aws-ami
This terraform module will deploy a CodeBuild project that will build an AMI and place the AMI ID in an SSM Parameter.

This module requires an active CodeStar Connection to the Github repository where the packer definition is stored, unless the repository is public.