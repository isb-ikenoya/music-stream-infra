variable "domain" {
  description = "自身のドメイン"
  type        = string
  sensitive   = true
}

variable "owner" {
  description = "作成者名"
  type        = string
}

variable "project" {
  description = "プロジェクト名"
  type        = string
}

variable "env" {
  description = "環境名"
  type        = string
}

variable "zone_id" {
  description = "対象のRoute53ゾーンID"
  type        = string
}
