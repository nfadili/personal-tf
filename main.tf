resource "digitalocean_project" "personal" {
  name        = "personal"
  environment = "Development"
  resources   = [digitalocean_kubernetes_cluster.personal_cluster.urn]
}

resource "digitalocean_kubernetes_cluster" "personal_cluster" {
  name    = "personal"
  region  = "nyc1"
  version = "1.26.3-do.0"

  node_pool {
    name       = "worker-pool"
    size       = "s-1vcpu-2gb"
    node_count = 1
  }
}
