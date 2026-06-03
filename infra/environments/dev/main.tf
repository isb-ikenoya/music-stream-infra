module "global_variables" {
  // 共通で使用する定数
  source = "../../modules/global-variables/"
}

locals {
  owner   = module.global_variables.owner
  project = module.global_variables.project
  env     = "dev"
}

module "dynamo-db" {
  source = "../../modules/dynamodb/"
  owner  = local.owner
}
