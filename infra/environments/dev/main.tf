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

module "route53" {
  source        = "../../modules/route53"
  parent_domain = var.parent_domain
  domain        = var.domain
  owner         = local.owner
  env           = local.env
  project       = local.project
}

module "acm" {
  source = "../../modules/acm"
  providers = {
    aws = aws.virginia
  }

  domain  = var.domain
  owner   = local.owner
  project = local.project
  env     = local.env
  zone_id = module.route53.zone_id

  depends_on = [module.route53]
}
