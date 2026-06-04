variable "parent_domain" {
  description = "親のドメイン"
  type        = string
  sensitive   = true
}

variable "domain" {
  description = "ドメイン"
  type        = string
}

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

