output "api_route" {
  description = "Base URL for API Gateway stage."

  value = "${aws_apigatewayv2_stage.this.invoke_url}/${local.resource_path}"
}
