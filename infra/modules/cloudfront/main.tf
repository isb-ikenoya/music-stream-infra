# SAMがデプロイしたCloudFormationスタックの情報を参照
data "aws_cloudformation_stack" "sam_stack" {
  name = "music-stream" # samconfig.toml に書いた stack_name と同じ名前
}

locals {
  # SAMのAPI Gateway ID
  sam_api_gateway_id = data.aws_cloudformation_stack.sam_stack.outputs["TargetApiId"]
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

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only" # API GatewayはHTTPS必須
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # デフォルトのキャッシュビヘイビアをAPI Gatewayに向ける
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "APIGatewayOrigin"

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
      # 重要：Hostヘッダーは含めない（API Gatewayが自身のURL以外を拒否するため）
      headers = ["Accept", "Authorization", "Content-Type"]
    }

    viewer_protocol_policy = "redirect-to-https"
    # APIなので基本はキャッシュさせない設定
    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
    compress    = true
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
