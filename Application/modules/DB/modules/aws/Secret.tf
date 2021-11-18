# Firstly we will create a random generated password which we will use in secrets.

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}


# Now create secret and secret versions for database master account 

resource "aws_secretsmanager_secret" "mongo_secret" {
  name = "mongo_creds"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "mongo_secret_version" {
  secret_id = aws_secretsmanager_secret.mongo_secret.id

  secret_string = <<EOF
   {
    "username": "user",
    "password": "${random_password.password.result}"
   }
EOF
}
