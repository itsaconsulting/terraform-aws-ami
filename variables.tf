variable "ami_source" {
  type        = string
  description = "The link to the GitHub project that contains the packer build definition."
  default     = "https://github.com/itsaconsulting/nat-gateway-ami"
}

variable "ami_ssm_parameter_name" {
  type        = string
  description = "The SSM Parameter to store the AMI ID in, after it is created.  This should include the region, so be sure to customize for your environment."
  default     = "/amis/linux/us-west-2/codebuild-ami-nat-gateway"
}

variable "subnet_id" {
  type        = string
  description = "The ID of the subnet to build the AMI in.  This should be a private subnet, with appropriate Nat Gateway or equivalent route to the internet."
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC to build the AMI in."
}

variable "tags" {
  type        = map(string)
  description = "The tags to apply to the resources."
  default = {
    "Name"        = "codebuild-ami"
    "Environment" = "development"
  }
}

variable "security_group_name_prefix" {
  type        = string
  description = "The prefix to apply to the security group name."
  default     = "codebuild-ami-sg"
}

variable "ami_codebuild_role_name_prefix" {
  type        = string
  description = "The prefix to apply to the IAM role name."
  default     = "codebuild-ami-role"
}

variable "ami_codebuild_policy_name_prefix" {
  type        = string
  description = "The prefix to apply to the IAM policy name."
  default     = "codebuild-ami-policy"
}

variable "codebuild_project_name" {
  type        = string
  description = "The name to apply to the CodeBuild project."
  default     = "codebuild-project-ami"
}

variable "aws_cloudwatch_event_rule_schedule" {
  type        = string
  description = "The schedule to trigger the AMI build on.  This is optional so that no trigger will be created if this is left blank."
  default     = ""
}

variable "branch" {
  type        = string
  description = "The branch to trigger the AMI build on, when commits are pushed."
  default     = "main"
}

variable "create_webhook" {
  type        = bool
  description = "Whether to create a webhook to trigger the AMI build on pushes to the branch."
  default     = false
}
