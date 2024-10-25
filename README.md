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

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | > 1.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.72.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.ami_build_trigger](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.ami_build_trigger_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_codebuild_project.ami_build](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |
| [aws_codebuild_webhook.ami_build_webhook](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_webhook) | resource |
| [aws_iam_policy.cloudwatch_event_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.ami_codebuild_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cloudwatch_event_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.ami_codebuild_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_security_group.ami_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_ssm_parameter.ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_vpc_security_group_egress_rule.ami_allow_all_traffic_ipv4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_codebuild_policy_name_prefix"></a> [ami\_codebuild\_policy\_name\_prefix](#input\_ami\_codebuild\_policy\_name\_prefix) | The prefix to apply to the IAM policy name. | `string` | `"codebuild-ami-policy"` | no |
| <a name="input_ami_codebuild_role_name_prefix"></a> [ami\_codebuild\_role\_name\_prefix](#input\_ami\_codebuild\_role\_name\_prefix) | The prefix to apply to the IAM role name. | `string` | `"codebuild-ami-role"` | no |
| <a name="input_ami_source"></a> [ami\_source](#input\_ami\_source) | The link to the GitHub project that contains the packer build definition. | `string` | `"https://github.com/itsaconsulting/nat-gateway-ami"` | no |
| <a name="input_ami_ssm_parameter_name"></a> [ami\_ssm\_parameter\_name](#input\_ami\_ssm\_parameter\_name) | The SSM Parameter to store the AMI ID in, after it is created.  This should include the region, so be sure to customize for your environment. | `string` | `"/amis/linux/us-west-2/codebuild-ami-nat-gateway"` | no |
| <a name="input_aws_cloudwatch_event_rule_schedule"></a> [aws\_cloudwatch\_event\_rule\_schedule](#input\_aws\_cloudwatch\_event\_rule\_schedule) | The schedule to trigger the AMI build on.  This is optional so that no trigger will be created if this is left blank. | `string` | `""` | no |
| <a name="input_branch"></a> [branch](#input\_branch) | The branch to trigger the AMI build on, when commits are pushed. | `string` | `"main"` | no |
| <a name="input_codebuild_project_name"></a> [codebuild\_project\_name](#input\_codebuild\_project\_name) | The name to apply to the CodeBuild project. | `string` | `"codebuild-project-ami"` | no |
| <a name="input_security_group_name_prefix"></a> [security\_group\_name\_prefix](#input\_security\_group\_name\_prefix) | The prefix to apply to the security group name. | `string` | `"codebuild-ami-sg"` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | The ID of the subnet to build the AMI in.  This should be a private subnet, with appropriate Nat Gateway or equivalent route to the internet. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | The tags to apply to the resources. | `map(string)` | <pre>{<br>  "Environment": "development",<br>  "Name": "codebuild-ami"<br>}</pre> | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC to build the AMI in. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ssm_parameter_nat_gateway_ami_id"></a> [ssm\_parameter\_nat\_gateway\_ami\_id](#output\_ssm\_parameter\_nat\_gateway\_ami\_id) | The SSM Parameter ARN that contains the AMI ID. |
