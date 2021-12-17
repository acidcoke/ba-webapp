variable "region" {
  default     = "eu-central-1"
  description = "AWS region"
}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.2.0"

  name                 = "ba-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "type"                                        = "private"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

resource "aws_security_group" "worker_mgmt" {
  name_prefix = "worker_management"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "efs" {
  name_prefix = "efs"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }
}

data "aws_security_group" "eks_cluster" {
  id = module.eks.cluster_primary_security_group_id
}

resource "random_string" "username" {
  length = 10
}

resource "random_password" "password" {
  length  = 20
  special = true
}

# Now create secret and secret versions for database master account 

resource "aws_secretsmanager_secret" "mongo_secret" {
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "mongo_secret_version" {
  secret_id = aws_secretsmanager_secret.mongo_secret.id

  secret_string = <<EOF
   {
    "username": "${random_string.username.result}",
    "password": "${random_password.password.result}"
   }
EOF
}


resource "aws_kms_key" "a" {}

resource "aws_iam_role" "a" {
  name = "iam-role-for-grant"

  assume_role_policy = <<EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "lambda.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
    }
    EOF
}

resource "aws_kms_grant" "a" {
  name              = "ba-grant"
  key_id            = aws_kms_key.a.key_id
  grantee_principal = aws_iam_role.a.arn
  operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
}



resource "aws_efs_file_system" "ba-efs" {
  kms_key_id = aws_kms_key.a.arn
  encrypted  = true
}

resource "aws_efs_mount_target" "private" {
  count           = length(module.vpc.private_subnets)
  file_system_id  = aws_efs_file_system.ba-efs.id
  subnet_id       = module.vpc.private_subnets[count.index]
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_backup_policy" "efs" {
  file_system_id = aws_efs_file_system.ba-efs.id
  backup_policy {
    status = "ENABLED"
  }
}


module "eks" {
  source                        = "terraform-aws-modules/eks/aws"
  cluster_name                  = local.cluster_name
  cluster_version               = "1.20"
  cluster_create_security_group = true

  cluster_encryption_config = [
    {
      provider_key_arn = aws_kms_key.a.arn
      resources        = ["secrets"]
    }
  ]

  subnets = module.vpc.private_subnets

  vpc_id = module.vpc.vpc_id

  workers_group_defaults = {
    root_volume_type = "gp2"
  }

  worker_groups = [
    {
      name                          = "ba-worker-group-1"
      instance_type                 = "t2.micro"
      additional_security_group_ids = [aws_security_group.worker_mgmt.id]
      asg_desired_capacity          = 1
    },
    {
      name                          = "ba-worker-group-2"
      instance_type                 = "t2.micro"
      additional_security_group_ids = [aws_security_group.worker_mgmt.id]
      asg_desired_capacity          = 1
    },
    {
      name                          = "ba-worker-group-3"
      instance_type                 = "t2.small"
      additional_security_group_ids = [aws_security_group.worker_mgmt.id]
      asg_desired_capacity          = 1
    }
  ]
}

locals {
  cluster_name = "ba-eks-${random_string.suffix.result}"
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}
