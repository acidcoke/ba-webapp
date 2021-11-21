provider "aws" {
  region = var.aws_region
}

resource "random_pet" "lambda_bucket_name" {
  prefix = "learn-terraform-functions"
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id

  acl           = "private"
  force_destroy = true
}

# generate an archive from the source code and upload it as an s3 object

data "archive_file" "lambda_hello_world" {
  type = "zip"

  source_dir  = "${path.module}/hello-world"
  output_path = "${path.module}/hello-world.zip"
}

resource "aws_s3_bucket_object" "lambda_hello_world" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "hello-world.zip"
  source = data.archive_file.lambda_hello_world.output_path

  etag = filemd5(data.archive_file.lambda_hello_world.output_path)
}

data "aws_secretsmanager_secret" "mongo_secret" {
  arn = var.mongo_secret
}

data "aws_secretsmanager_secret_version" "mongo_credentials" {
  secret_id = data.aws_secretsmanager_secret.mongo_secret.arn
}

locals {
  db_creds = jsondecode(
    data.aws_secretsmanager_secret_version.mongo_credentials.secret_string
  )
}
# create lambda function


data "aws_subnet_ids" "vpc" {
  vpc_id = var.vpc_id
}

data "aws_security_groups" "vpc" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

resource "aws_lambda_function" "hello_world" {
  function_name = "HelloWorld"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_bucket_object.lambda_hello_world.key

  runtime = "python3.7"
  handler = "hello.handler"

  source_code_hash = data.archive_file.lambda_hello_world.output_base64sha256

  role   = aws_iam_role.lambda_exec.arn
  layers = [aws_lambda_layer_version.python37-pymongo-layer.arn]
  vpc_config {
    subnet_ids         = data.aws_subnet_ids.vpc.ids
    security_group_ids = data.aws_security_groups.vpc.ids
  }

  environment {
    variables = {
      MONGO_URI = local.mongo_uri
    }
  }
}

locals {
  mongo_credentials = jsondecode(data.aws_secretsmanager_secret_version.mongo_credentials.secret_string)
  mongo_uri         = "mongodb://${local.mongo_credentials["username"]}:${local.mongo_credentials["password"]}@${var.mongodb_ingress_hostname}"
}

resource "aws_lambda_layer_version" "python37-pymongo-layer" {
  filename                 = "${path.module}/pymongo_layer.zip"
  layer_name               = "Python37-pymongo"
  source_code_hash         = filebase64sha256("${path.module}/pymongo_layer.zip")
  compatible_runtimes      = ["python3.7"]
  compatible_architectures = ["x86_64"]
}

resource "aws_cloudwatch_log_group" "hello_world" {
  name = "/aws/lambda/${aws_lambda_function.hello_world.function_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}





resource "aws_apigatewayv2_api" "lambda" {
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["*"]
  }
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "serverless_lambda_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "post" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.hello_world.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

locals {
  resource_path = "/entries"
}

resource "aws_apigatewayv2_route" "create_entries" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "POST ${local.resource_path}"
  target    = "integrations/${aws_apigatewayv2_integration.post.id}"
}
resource "aws_apigatewayv2_route" "get_entries" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET ${local.resource_path}"
  target    = "integrations/${aws_apigatewayv2_integration.post.id}"
}


resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"

  retention_in_days = 30
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello_world.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}
