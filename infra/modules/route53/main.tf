# 既存の親のホストゾーンの情報を取得する（データソース）
data "aws_route53_zone" "parent" {
  name         = var.parent_domain # 既存のドメイン名
  private_zone = false             # パブリックの場合
}

# 自身のゾーンを作成する
resource "aws_route53_zone" "public_zone" {
  name          = var.domain
  force_destroy = false

  tags = {
    created_by = var.owner
    Name       = "${var.project}-${var.env}-domain"
    Project    = var.project
    Env        = var.env
  }
}

# 親のゾーンに、作成した子ゾーンのNSレコードを追加する
resource "aws_route53_record" "parent_ns_delegation" {
  zone_id = data.aws_route53_zone.parent.zone_id
  name    = var.domain # 子ドメイン名（例: sub.example.com）
  type    = "NS"
  ttl     = "172800" # NSレコードの標準的なTTL（2日間）

  # 作成した新しいゾーンが持つ4つのネームサーバーを指定
  records = aws_route53_zone.public_zone.name_servers
}
