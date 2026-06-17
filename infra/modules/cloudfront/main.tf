# SAMがデプロイしたCloudFormationスタックの情報を参照
data "aws_cloudformation_stack" "sam_stack" {
  name = "music-stream" # samconfig.toml に書いた stack_name と同じ名前
}

locals {
  # SAMのAPI Gateway ID
  sam_api_gateway_id = data.aws_cloudformation_stack.sam_stack.outputs["TargetApiId"]
}

# ストリーミングバケットのアクセスコントロール
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "music-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront
resource "aws_cloudfront_distribution" "this" {
  # 基本設定

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "WebDaw用"
  default_root_object = "index.html"
  aliases             = [var.aliase_domain]

  tags = {
    Name       = "WebDaw-CloudFront"
    created_by = var.owner
  }

  # 価格クラス
  price_class = "PriceClass_200" # アジア・ヨーロッパ・北米をカバー

  # アクセス制限（地域設定は料金がかからない？）
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["JP"] # 日本のみアクセス可能
    }
  }

  # Lambda（API Gateway）
  origin {
    domain_name = "${local.sam_api_gateway_id}.execute-api.ap-northeast-1.amazonaws.com"
    origin_id   = "APIGatewayOrigin"
    origin_path = "/Prod"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only" # API GatewayはHTTPS必須
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # 音楽ストリーミング用S3
  origin {
    domain_name = var.music_streaming_s3_domain_name
    origin_id   = "music-streaming-s3-origin"

    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  # デフォルトのキャッシュビヘイビアをAPI Gatewayに向ける
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "APIGatewayOrigin"

    viewer_protocol_policy = "redirect-to-https"

    # APIはキャッシュ無効
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"

    compress = true
  }

  # 証明書
  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  /*custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html" # SPAのルーティング対応
  }*/

}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${var.music_streaming_s3_bucket_arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.this.arn]
    }
  }
}

# CloudFrontからのアクセスのみを許可するポリシー (OAC)
resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = var.music_streaming_s3_bucket_id
  policy = data.aws_iam_policy_document.s3_policy.json
}

# CloudFrontのURLをRoute53に登録

# 対象のホストゾーンの情報を取得する（データソース）
data "aws_route53_zone" "this" {
  name         = var.aliase_domain # 対象のドメイン
  private_zone = false             # パブリックの場合
}

# Aレコードを追加する
resource "aws_route53_record" "record_a" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.aliase_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}

# AAAAレコードを追加する
resource "aws_route53_record" "record_aaaa" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.aliase_domain
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}
