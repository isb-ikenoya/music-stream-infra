output "domain_name" {
  value = aws_s3_bucket.music_bucket.bucket_regional_domain_name
}

output "bucket_id" {
  value = aws_s3_bucket.music_bucket.id
}

output "bucket_arn" {
  value = aws_s3_bucket.music_bucket.arn
}
