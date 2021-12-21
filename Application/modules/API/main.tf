#####################################################################
# PROVIDER CONFIGURATION                                            #
#####################################################################

provider "aws" {
  region = var.aws_region
}

#####################################################################
# LAMBDA CONFIGURATION                                              #
#####################################################################

data "aws_vpc" "this" {
  id = var.vpc_id
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  tags = {
    type = "private"
  }
}

resource "aws_security_group" "this" {
  name   = "${var.name_prefix}-Lambda"
  vpc_id = var.vpc_id
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = [data.aws_vpc.this.cidr_block]
  }
  egress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/* SOURCE FOR LAMBDA */

data "archive_file" "this" {
  type = "zip"

  source_dir  = "${path.module}/code"
  output_path = "${path.module}/code.zip"
}

resource "aws_lambda_layer_version" "python37_pymongo" {
  filename                 = "${path.module}/pymongo_layer.zip"
  layer_name               = "Python37-pymongo"
  source_code_hash         = filebase64sha256("${path.module}/pymongo_layer.zip")
  compatible_runtimes      = ["python3.7"]
  compatible_architectures = ["x86_64"]
}

resource "aws_lambda_function" "this" {
  function_name = "${var.name_prefix}-APICode"

  filename = "${path.module}/code.zip"

  runtime = "python3.7"
  handler = "api.handler"

  source_code_hash = data.archive_file.this.output_base64sha256

  role   = aws_iam_role.this.arn
  layers = [aws_lambda_layer_version.python37_pymongo.arn]
  vpc_config {
    subnet_ids         = data.aws_subnets.private.ids
    security_group_ids = [aws_security_group.this.id]
  }

  environment {
    variables = {
      MONGO_BASE_URL = var.mongodb_ingress_hostname
      SECRET_ARN     = var.mongodb_secret
    }
  }
}

/* LOGGING FOR LAMBDA */

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.this.function_name}"
  retention_in_days = 30
}

/* IAM FOR LAMBDA */

resource "aws_lambda_permission" "api_gw" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}

resource "aws_iam_role" "this" {
  name = "${var.name_prefix}-LambdaExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "this" {
  name = "${var.name_prefix}-LambdaSecretAccessPolicy"
  role = aws_iam_role.this.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "secretsmanager:GetSecretValue"
      Effect   = "Allow"
      Resource = "${var.mongodb_secret}"
      }
    ]
  })
}


#####################################################################
# API CONFIGURATION                                                 #
#####################################################################


resource "aws_apigatewayv2_api" "this" {
  name          = "${var.name_prefix}-Lambda"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["*"]
  }
}

resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "${var.name_prefix}-Lambda"
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

resource "aws_apigatewayv2_integration" "this" {
  api_id             = aws_apigatewayv2_api.this.id
  integration_uri    = aws_lambda_function.this.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

locals {
  resource_path = "/entries"
  route_target  = "integrations/${aws_apigatewayv2_integration.this.id}"
}

resource "aws_apigatewayv2_route" "create_entries" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST ${local.resource_path}"
  target    = local.route_target
}

resource "aws_apigatewayv2_route" "get_entries" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET ${local.resource_path}"
  target    = local.route_target
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "api_gw/${aws_apigatewayv2_api.this.name}"
  retention_in_days = 30
}
