terraform {
  required_version = ">= 1.14.0"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.8.1"
    }
  }
  cloud {
    organization = "isb-ikenoya-study"
    workspaces {
      name = "music-stream"
    }
  }
}
