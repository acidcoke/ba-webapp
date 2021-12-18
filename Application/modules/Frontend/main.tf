provider "aws" {
  region = var.aws_region
}

# AWS S3 bucket for static hosting
resource "aws_s3_bucket" "website" {
  bucket = var.website_bucket_name
  acl    = "public-read"

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["POST", "GET"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::${var.website_bucket_name}/*"
      }
    ]
    }
  )

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

# AWS S3 bucket for www-redirect
resource "aws_s3_bucket" "website_redirect" {
  bucket = "www.${var.website_bucket_name}"
  acl    = "public-read"

  website {
    redirect_all_requests_to = var.website_bucket_name
  }
}

resource "aws_s3_bucket_object" "this" {
  bucket       = aws_s3_bucket.website.id
  content      = local.content
  key          = "index.html"
  content_type = "text/html"
}

locals {
  content = templatefile("${path.module}/template/index.html", { url = var.api_route })
}
