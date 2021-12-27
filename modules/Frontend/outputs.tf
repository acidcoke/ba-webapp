output "website" {
  value = aws_s3_bucket.website.website
}

output "website_domain" {
  value = aws_s3_bucket.website.website_domain
}

output "website_endpoint" {
  value = aws_s3_bucket.website.website_endpoint
}
