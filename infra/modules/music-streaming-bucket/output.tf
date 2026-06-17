output "domain_name" {
  value = aws_s3_bucket.music_bucket.bucket_regional_domain_name
}
