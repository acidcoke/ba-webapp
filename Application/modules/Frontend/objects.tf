resource "aws_s3_bucket_object" "object" {
  bucket       = aws_s3_bucket.website.id
  content      = local.content
  key          = "index.html"
  content_type = "text/html"
}

locals {
  content = templatefile("${path.module}/template/index.html", { url = var.api_route })
}
