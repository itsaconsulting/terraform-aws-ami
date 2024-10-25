# terraform-aws-ami
This terraform module will deploy a CodeBuild project that will build an AMI and place the AMI ID in an SSM Parameter.

This module requires an active CodeStar Connection to the Github repository where the packer definition is stored, unless the repository is public.

A sample terragrunt.hcl would look like this:

```
locals {
  region_vars = yamldecode(file(find_in_parent_folders("region.yaml")))

  module_version = "0.3.0"

  aws_cloudwatch_event_rule_schedule = "0 6 ? * MON *"
  aws_region                         = local.region_vars["aws_region"]
  ami_source                         = "https://github.com/itsaconsulting/nat-gateway-ami"
  subnet_id                          = "subnet-xxxxxxxxx"
}

include {
  path = find_in_parent_folders()
}

terraform {
  source = "git::https://github.com/itsaconsulting/terraform-aws-ami?ref=${local.module_version}"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"
}
EOF
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "s3" {}
}
EOF
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs_allowed_terraform_commands = ["validate"]
  mock_outputs = { 
    vpc_id = "mock-vpc-id"
  }
}

inputs = { 
  aws_cloudwatch_event_rule_schedule = local.aws_cloudwatch_event_rule_schedule
  ami_source                         = local.ami_source
  subnet_id                          = local.subnet_id
  vpc_id                             = dependency.vpc.outputs.vpc_id
}
```