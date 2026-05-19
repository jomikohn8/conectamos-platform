# =============================================================================
# OUTPUTS — usados por el workflow de CI para sync y invalidación
# =============================================================================

output "s3_bucket_name" {
  description = "S3 bucket name — used by CI for aws s3 sync"
  value       = aws_s3_bucket.app.bucket
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID — used by CI for cache invalidation"
  value       = aws_cloudfront_distribution.app.id
}

output "cloudfront_domain" {
  description = "CloudFront default domain (*.cloudfront.net) — use custom_domain for production traffic"
  value       = "https://${aws_cloudfront_distribution.app.domain_name}"
}

output "site_url" {
  description = "Effective public URL"
  value       = "https://${local.custom_domain}"
}

output "acm_certificate_validation_records" {
  description = "CNAME records for ACM DNS validation. Create in Cloudflare (DNS-only, no proxy)."
  value       = aws_acm_certificate.app.domain_validation_options
}
