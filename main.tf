# Configure the AWS provider. Terraform will create resources in this region.
provider "aws" {
  region = "us-east-1"
}

# Create the S3 bucket that will store the portfolio website files.
resource "aws_s3_bucket" "portfolio" {
  bucket = "boris-portfolio-site-2026"

  # Add a name tag to help identify the bucket in AWS.
  tags = {
    Name = "PortfolioSite"
  }
}

# Build a set of website file paths to upload to S3.
locals {
  website_files = toset(concat(
    # Always include the website's home page.
    ["index.html"],

    # Find files under each website folder and exclude files whose names start with a dot.
    [for file in fileset("${path.module}/website/css", "**") : "css/${file}" if !startswith(basename(file), ".")],
    [for file in fileset("${path.module}/website/js", "**") : "js/${file}" if !startswith(basename(file), ".")],
    [for file in fileset("${path.module}/website/img", "**") : "img/${file}" if !startswith(basename(file), ".")]
  ))
}

# Upload each selected website file as a separate S3 object.
resource "aws_s3_object" "website_files" {
  # Create one S3 object for each path in local.website_files.
  for_each = local.website_files

  # Use the S3 bucket created above.
  bucket = aws_s3_bucket.portfolio.id

  # Set the S3 object key, preserving folders such as css/ and img/.
  key = each.value

  # Find the file to upload in the local website/ directory.
  source = "${path.module}/website/${each.value}"

  # Re-upload the object when the local file's contents change.
  etag = filemd5("${path.module}/website/${each.value}")

  # Set the object's Content-Type based on its extension so browsers handle it correctly.
  # Use application/octet-stream if the extension isn't listed.
  content_type = lookup({
    html = "text/html"
    css  = "text/css"
    js   = "application/javascript"
    svg  = "image/svg+xml"
    webp = "image/webp"
  }, lower(element(reverse(split(".", each.value)), 0)), "application/octet-stream")
}

# Create an Origin Access Control (OAC) so CloudFront can securely access the S3 bucket.
resource "aws_cloudfront_origin_access_control" "portfolio" {
  name        = "portfolio-oac"
  description = "OAC for portfolio site"

  # Specify that the origin is an S3 bucket.
  origin_access_control_origin_type = "s3"

  # Sign every request sent to S3 using AWS Signature Version 4.
  signing_behavior  = "always"
  signing_protocol  = "sigv4"
}

# Create the CloudFront distribution that delivers the website to visitors.
resource "aws_cloudfront_distribution" "portfolio" {
  enabled             = true
  default_root_object = "index.html"

  # Limit which CloudFront edge locations can serve the site.
  price_class = "PriceClass_100"

  # Configure the S3 bucket as CloudFront's origin.
  origin {
    domain_name = aws_s3_bucket.portfolio.bucket_regional_domain_name
    origin_id   = "portfolio-s3-origin"

    # Attach the OAC to authenticate CloudFront's requests to S3.
    origin_access_control_id = aws_cloudfront_origin_access_control.portfolio.id
  }

  # Configure how CloudFront handles requests that don't match another behavior.
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "portfolio-s3-origin"
    viewer_protocol_policy = "redirect-to-https"

    # Do not include query strings or cookies in the cache key or forward them to S3.
    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  # Allow visitors from all geographic locations.
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Use the default CloudFront certificate for HTTPS on the CloudFront domain.
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# Attach a policy to the S3 bucket that lets this CloudFront distribution read objects.
resource "aws_s3_bucket_policy" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id

  # Build the bucket policy as JSON.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"

        # Identify CloudFront as the service allowed to access the bucket.
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }

        # Allow CloudFront to retrieve website files, but not modify them.
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.portfolio.arn}/*"

        # Restrict access to requests from this specific distribution.
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.portfolio.arn
          }
        }
      }
    ]
  })
}