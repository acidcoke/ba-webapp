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

