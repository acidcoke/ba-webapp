############################################################################################
# PROVIDER CONFIGURATION                                                                   #
############################################################################################

provider "aws" {
  region = var.aws_region
}

############################################################################################
# LAMBDA CONFIGURATION                                                                     #
############################################################################################

/* NETWORK FOR LAMBDA*/
data "aws_subnet" "private" {
  count = length(var.private_subnet_ids)
  id    = var.private_subnet_ids[count.index]
}

resource "aws_security_group" "lambda" {
  name_prefix = "${var.name_prefix}-Lambda2Mongodb"
  description = "allow lambda to connect to mongodb"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "egress_mongodb" {
  security_group_id = aws_security_group.lambda.id
  type              = "egress"
  from_port         = 27017
  to_port           = 27017
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress_secretsmanager" {
  security_group_id = aws_security_group.lambda.id
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
}

/* SOURCE FOR LAMBDA */

data "archive_file" "this" {
  type = "zip"

  source_dir  = "${path.module}/code"
  output_path = "${path.module}/code.zip"
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
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      MONGO_BASE_URL = var.mongodb_ingress_hostname
      SECRET_ARN     = var.mongo_secret
    }
  }
}

resource "aws_lambda_layer_version" "python37_pymongo" {
  filename                 = "${path.module}/pymongo_layer.zip"
  layer_name               = "Python37-pymongo"
  source_code_hash         = filebase64sha256("${path.module}/pymongo_layer.zip")
  compatible_runtimes      = ["python3.7"]
  compatible_architectures = ["x86_64"]
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
  name_prefix = "${var.name_prefix}-LambdaExecutionRole"
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

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.this.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access_execution" {
  role       = aws_iam_role.this.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "this" {
  name_prefix = "${var.name_prefix}-LambdaSecretAccessPolicy"
  role        = aws_iam_role.this.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "secretsmanager:GetSecretValue"
      Effect   = "Allow"
      Resource = "${var.mongo_secret}"
      }
    ]
  })
}


############################################################################################
# API CONFIGURATION                                                                        #
############################################################################################


resource "aws_apigatewayv2_api" "this" {
  name          = "${var.name_prefix}-lambda_api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["*"]
  }
}

resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "${var.name_prefix}-lambda_stage"
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
  name = "api_gw/${aws_apigatewayv2_api.this.name}"

  retention_in_days = 30
}



############################################################################################
# NETWORK FOR SECRETS MANAGER                                                              #
############################################################################################

resource "aws_security_group" "this" {
  name_prefix = "${var.name_prefix}-Secretsmanager"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = data.aws_subnet.private[*].cidr_block
  }

  tags = {
    use = "secretsmanager"
  }
}

resource "aws_vpc_endpoint" "this" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.eu-central-1.secretsmanager"
  private_dns_enabled = true
  security_group_ids  = resource.aws_security_group.this[*].id
  subnet_ids          = var.private_subnet_ids
  vpc_endpoint_type   = "Interface"
}
