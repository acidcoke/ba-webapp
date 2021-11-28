provider "aws" {
  region = var.aws_region
}

data "archive_file" "lambda_hello_world" {
  type = "zip"

  source_dir  = "${path.module}/code"
  output_path = "${path.module}/code.zip"
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


data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  tags = {
    type = "private"
  }
}

resource "aws_security_group" "lambda" {
  vpc_id = var.vpc_id
  egress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lambda_function" "hello_world" {
  function_name = "HelloWorld"

  filename = "${path.module}/code.zip"

  runtime = "python3.7"
  handler = "api.handler"

  source_code_hash = data.archive_file.lambda_hello_world.output_base64sha256

  role   = aws_iam_role.lambda_exec.arn
  layers = [aws_lambda_layer_version.python37-pymongo-layer.arn]
  vpc_config {
    subnet_ids         = data.aws_subnets.private.ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      MONGO_URI      = local.mongo_uri
      MONGO_BASE_URL = var.mongodb_ingress_hostname
      SECRET_ARN = var.mongo_secret
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

resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment_lambda_vpc_access_execution" {
  role       = aws_iam_role.lambda_exec.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "secret" {
  role       = aws_iam_role.lambda_exec.id
  policy_arn = aws_iam_policy.secret.arn
}

resource "aws_iam_policy" "secret" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "secretsmanager:GetSecretValue"
      Effect   = "Allow"
      Resource = var.mongo_secret
      }
    ]
  })
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
