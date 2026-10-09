# Display the CloudFront URL for the portfolio website.
output "cloudfront_url" {
  # Describe this output in Terraform's output listing.
  description = "URL of the portfolio website"

  # Build the HTTPS URL from the distribution's assigned domain name.
  value = "https://${aws_cloudfront_distribution.portfolio.domain_name}"
}