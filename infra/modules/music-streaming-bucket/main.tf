data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.music_bucket.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.main.arn]
    }
  }
}

# 音楽ファイル格納用バケット
resource "aws_s3_bucket" "music_bucket" {
  bucket = "music-streaming-bucket"
  tags = {
    "created_by" = var.owner
  }
}

# パブリックアクセス禁止
resource "aws_s3_bucket_public_access_block" "music_bucket_block" {
  bucket = aws_s3_bucket.music_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFrontからのアクセスのみを許可するポリシー (OAC)
resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = aws_s3_bucket.music_bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json
}
