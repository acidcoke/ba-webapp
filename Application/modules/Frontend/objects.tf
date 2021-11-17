resource "aws_s3_bucket_object" "object" {
  bucket = aws_s3_bucket.website.id
  key    = "index.html"
  source = "${path.module}/website/index.html"
  source_hash = filebase64sha256("${path.module}/website/index.html")
  content_type = "text/html"
}


resource "local_file" "dotfiles" {
    content  = templatefile("${path.module}/website/index.html", {url=var.base_url})
    filename = "index.html"
}