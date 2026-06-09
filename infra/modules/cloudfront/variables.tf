variable "owner" {
  description = "作成者名"
  type        = string
}

variable "env" {
  description = "環境名"
  type        = string
}

variable "project" {
  description = "プロジェクト名"
  type        = string
}

variable "acm_certificate_arn" {
  description = "証明書arn"
  type        = string
}

variable "aliase_domain" {
  description = "代替ドメイン"
  type        = string
}
