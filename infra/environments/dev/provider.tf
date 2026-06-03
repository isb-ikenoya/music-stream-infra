provider "aws" {
  # OIDC経由で実行するため、認証情報は不要
  region = "ap-northeast-1"
}

# CloudFront用（ACM専用）のプロバイダー（バージニア北部）
provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}
