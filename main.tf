resource "digitalocean_kubernetes_cluster" "kubernetes_cluster" {
  name    = "personal"
  region  = "nyc1"
  version = "1.26.3-do.0"

  node_pool {
    name       = "worker-pool"
    size       = "s-1vcpu-2gb"
    node_count = 1
  }
}
