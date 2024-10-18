variable "aws_account_id" {
  type        = string
  description = "The AWS account ID to create resources in."
}

variable "aws_region" {
  type        = string
  description = "The AWS Region to create the CodeBuild project and AMI in."
  default     = "us-west-2"
}

variable "ami_source" {
  type        = string
  description = "The link to the GitHub project that contains the packer build definition."
  default     = "https://github.com/itsaconsulting/nat-gateway-ami"
}

variable "ami_ssm_parameter_name" {
  type        = string
  description = "The SSM Parameter to store the AMI ID in, after it is created."
  default     = "/amis/linux/codebuild-ami"
}

variable "subnet_id" {
  type        = string
  description = "The ID of the subnet to build the AMI in."
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC to build the AMI in."
}

variable "tags" {
  type        = map(string)
  description = "The tags to apply to the resources."
  default    = {
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
  default     = "codebuild-project-ami-project"
}