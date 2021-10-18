resource "aws_s3_bucket_object" "object" {
  bucket = aws_s3_bucket.website.id
  key    = "index.html"
  source = "${path.module}/index.html"
  content_type = "text/html"
}


resource "local_file" "dotfiles" {
    content  = templatefile("${path.module}/website/index.html", {url=aws_apigatewayv2_stage.lambda.invoke_url})
    filename = "index.html"
}