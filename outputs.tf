output "ssm_parameter_nat_gateway_ami_id" {
  value       = try(aws_ssm_parameter.ami.arn, "")
  sensitive   = true
  description = "The SSM Parameter ARN that contains the AMI ID."
}
