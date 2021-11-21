module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = local.cluster_name
  cluster_version = "1.20"
  subnets         = module.vpc.private_subnets

  vpc_id = module.vpc.vpc_id

  workers_group_defaults = {
    root_volume_type = "gp2"
  }

  worker_groups = [
    {
      name                          = "ba-worker-group-1"
      instance_type                 = "t2.micro"
      additional_userdata           = "echo foo bar"
      # changes can only be applied on a destroyed cluster, otherwise kubernetes errors
      asg_desired_capacity          = 1
      additional_security_group_ids = [aws_security_group.worker_mgmt.id]
    },
    {
      name                          = "ba-worker-group-2"
      instance_type                 = "t2.small"
      additional_userdata           = "echo foo bar"
      additional_security_group_ids = [aws_security_group.worker_mgmt.id]
      asg_desired_capacity          = 1
    },
  ]
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}
