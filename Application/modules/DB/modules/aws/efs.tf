resource "aws_efs_file_system" "ba-efs" {
  creation_token = "efs"
  kms_key_id     = aws_kms_key.a.arn
  encrypted      = true
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