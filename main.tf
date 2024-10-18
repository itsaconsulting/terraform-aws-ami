resource "aws_ssm_parameter" "ami" {
  name      = var.ami_ssm_parameter_name
  type      = "String"
  data_type = "aws:ec2:image"
  value     = "ami-00000000000000000"

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_security_group" "ami_sg" {
  name_prefix = "${var.security_group_name_prefix}-"
  description = "Allow all outbound traffic."
  vpc_id      = var.vpc_id

  tags = var.tags
}

resource "aws_vpc_security_group_egress_rule" "ami_allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.ami_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_iam_role" "ami_codebuild_role" {
  name_prefix = "${var.ami_codebuild_role_name_prefix}-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "codebuild.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "ami_codebuild_policy" {
  name_prefix = "${var.ami_codebuild_policy_name_prefix}-"
  role        = aws_iam_role.ami_codebuild_role.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "PackerTemporaryInstanceProfile",
        "Effect" : "Allow",
        "Action" : [
          "iam:PassRole",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:GetRole",
          "iam:GetInstanceProfile",
          "iam:DeleteRolePolicy",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:PutRolePolicy",
          "iam:AddRoleToInstanceProfile"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "PackerBuildPermissions",
        "Effect" : "Allow",
        "Action" : [
          "ec2:AttachVolume",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:CopyImage",
          "ec2:CreateImage",
          "ec2:CreateKeyPair",
          "ec2:CreateSecurityGroup",
          "ec2:CreateSnapshot",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:DeleteKeyPair",
          "ec2:DeleteSecurityGroup",
          "ec2:DeleteSnapshot",
          "ec2:DeleteVolume",
          "ec2:DeregisterImage",
          "ec2:DescribeImageAttribute",
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeRegions",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSnapshots",
          "ec2:DescribeSubnets",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DetachVolume",
          "ec2:GetPasswordData",
          "ec2:ModifyImageAttribute",
          "ec2:ModifyInstanceAttribute",
          "ec2:ModifySnapshotAttribute",
          "ec2:RegisterImage",
          "ec2:RunInstances",
          "ec2:StopInstances",
          "ec2:TerminateInstances"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "CodeBuildPermissions",
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeDhcpOptions",
          "ec2:DescribeImages",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "iam:PassRole"
        ],
        "Resource" : [
          "*"
        ]
      },
      {
        "Sid" : "AlsoCodeBuildPermissions",
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateNetworkInterfacePermission"
        ],
        "Resource" : "arn:aws:ec2:${var.aws_region}:${var.aws_account_id}:network-interface/*",
        "Condition" : {
          "StringEquals" : {
            "ec2:AuthorizedService" : "codebuild.amazonaws.com"
          },
          "ArnEquals" : {
            "ec2:Subnet" : [
              "arn:aws:ec2:${var.aws_region}:${var.aws_account_id}:subnet/${var.subnet_id}"
            ]
          }
        }
      },
      {
        "Sid" : "UpdateSSMParam",
        "Action" : "ssm:PutParameter",
        "Effect" : "Allow",
        "Resource" : aws_ssm_parameter.ami.arn,
      },
      {
        "Sid" : "GetSSMParam",
        "Action" : "ssm:GetParameters",
        "Effect" : "Allow",
        "Resource" : "*"
      },
      {
        "Sid" : "ConnectSSM",
        "Action" : [
          "ssm:StartSession",
          "ssm:TerminateSession"
        ],
        "Effect" : "Allow",
        "Resource" : "*"
      },
      {
        "Sid" : "CodeConnectionAccess",
        "Effect" : "Allow",
        "Action" : [
          "codestar-connections:GetConnectionToken",
          "codestar-connections:GetConnection",
          "codestar-connections:UseConnection",
          "codeconnections:GetConnectionToken",
          "codeconnections:GetConnection",
          "codeconnections:UseConnection"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_codebuild_project" "ami_build" {
  name          = var.codebuild_project_name
  build_timeout = "15"
  service_role  = aws_iam_role.ami_codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
  }

  source {
    location = var.ami_source
    buildspec = templatefile("templates/codebuild/buildspec.yml.tftpl",
      {
        ssm_parameter_name = var.ami_ssm_parameter_name
        subnet_id          = var.subnet_id
      }
    )
    git_clone_depth = 1
    type            = "GITHUB"
  }

  vpc_config {
    security_group_ids = [aws_security_group.ami_sg.id]
    subnets            = [var.subnet_id]
    vpc_id             = var.vpc_id
  }
}

resource "aws_codebuild_webhook" "ami_build_webhook" {
  project_name = aws_codebuild_project.ami_build.name
  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }

    filter {
      type    = "HEAD_REF"
      pattern = "refs/heads/main"
    }
  }
}
