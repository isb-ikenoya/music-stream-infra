# ランダムIDを生成（例: 8桁の16進数）
resource "random_id" "bucket_suffix" {
  byte_length = 4 # 4バイト = 8桁の16進数
}

# 音楽ファイル格納用バケット
resource "aws_s3_bucket" "music_bucket" {
  bucket = "music-streaming-bucket-${random_id.bucket_suffix.hex}"
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
