resource "aws_efs_file_system" "example" {
  creation_token = "mega-efs-example"
   kms_key_id = aws_kms_key.a.arn
  encrypted = true
}

resource "aws_efs_mount_target" "example-pri" {
  count          = length(module.vpc.private_subnets)
  file_system_id = aws_efs_file_system.example.id
  subnet_id      = module.vpc.private_subnets[count.index]
  security_groups = [ aws_security_group.efs.id ]
}

/* resource "aws_efs_mount_target" "example-pub" {
  count          = length(module.vpc.public_subnets)
  file_system_id = aws_efs_file_system.example.id
  subnet_id      = module.vpc.public_subnets[count.index]
  security_groups = [ aws_security_group.efs.id ]
} */