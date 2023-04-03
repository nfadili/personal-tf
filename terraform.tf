# Configure Terraform Cloud
terraform {

  cloud {
    organization = "nfadili"

    workspaces {
      name = "learn-terraform-cloud"
    }
  }

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }

  required_version = ">= 0.14.0"
}

# Set the variable value in *.tfvars file or using -var="do_token=..." CLI option
variable "do_token" {}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}
