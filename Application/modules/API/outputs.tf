

output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.hello_world.function_name
}

output "api_route" {
  description = "Base URL for API Gateway stage."

  value = "${aws_apigatewayv2_stage.lambda.invoke_url}/${local.resource_path}"
}