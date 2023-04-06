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
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0.1"
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

# Configure the kubernetes provider with credentials for the personal kubernetes cluster
provider "kubernetes" {
  host  = digitalocean_kubernetes_cluster.personal_kubernetes_cluster.endpoint
  token = digitalocean_kubernetes_cluster.personal_kubernetes_cluster.kube_config[0].token

  cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.personal_kubernetes_cluster.kube_config[0].cluster_ca_certificate
  )
}

# Configure the helm provider with credentaisl for the personal kubernetes cluster
provider "helm" {
  kubernetes {
    host  = digitalocean_kubernetes_cluster.personal_kubernetes_cluster.endpoint
    token = digitalocean_kubernetes_cluster.personal_kubernetes_cluster.kube_config[0].token

    cluster_ca_certificate = base64decode(
      digitalocean_kubernetes_cluster.personal_kubernetes_cluster.kube_config[0].cluster_ca_certificate
    )
  }
}
