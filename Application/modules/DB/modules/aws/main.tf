provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.2.0"

  name                 = var.name_prefix
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

resource "aws_security_group" "efs" {
  name_prefix = "${var.name_prefix}-EFS"
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

resource "random_string" "username" {
  length = 10
}

resource "random_password" "password" {
  length  = 20
  special = true
}

# Now create secret and secret versions for database master account 

resource "aws_secretsmanager_secret" "mongodb" {
  name_prefix             = "${var.name_prefix}-mongodb"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "mongodb" {
  secret_id = aws_secretsmanager_secret.mongodb.id

  secret_string = jsonencode(
    {
      username = "${random_string.username.result}"
      password = "${random_password.password.result}"
    }
  )
}


resource "aws_kms_key" "this" {}

resource "aws_iam_role" "this" {
  name_prefix = "${var.name_prefix}-KMSGrant"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_kms_grant" "this" {
  name              = var.name_prefix
  key_id            = aws_kms_key.this.key_id
  grantee_principal = aws_iam_role.this.arn
  operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
}

resource "aws_efs_file_system" "this" {
  kms_key_id = aws_kms_key.this.arn
  encrypted  = true
}

resource "aws_efs_mount_target" "this" {
  count           = length(module.vpc.private_subnets)
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = module.vpc.private_subnets[count.index]
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_backup_policy" "this" {
  file_system_id = aws_efs_file_system.this.id
  backup_policy {
    status = "ENABLED"
  }
}


module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = local.cluster_name
  cluster_version = "1.20"
  cluster_encryption_config = [
    {
      provider_key_arn = aws_kms_key.this.arn
      resources        = ["secrets"]
    }
  ]

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.private_subnets

  workers_group_defaults = { root_volume_type = "gp2" }

  worker_groups = [
    {
      name                 = "workers-0"
      instance_type        = "t2.small"
      asg_desired_capacity = 1
    },
    {
      name                 = "workers-1"
      instance_type        = "t2.small"
      asg_desired_capacity = 1
    },
    {
      name                 = "workers-2"
      instance_type        = "t2.small"
      asg_desired_capacity = 1
    }
  ]
}

locals {
  cluster_name = var.name_prefix
}

data "aws_eks_cluster" "this" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_id
}
