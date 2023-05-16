terraform {
  cloud {
    organization = "Y0sh1-personal"

    workspaces {
      name = "github-provisioning"
    }
  }
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}
