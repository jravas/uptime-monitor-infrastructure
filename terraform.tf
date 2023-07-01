terraform {
  cloud {
    organization = "prototyp-dev"
    workspaces {
      name = "uptime-monitor-infrastructure"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  required_version = ">= 0.14.0"
}
