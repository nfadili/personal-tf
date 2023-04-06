#####################################
# Shared/core resources
#####################################
resource "digitalocean_project" "personal" {
  name        = "personal"
  environment = "Development"
  resources = [
    digitalocean_kubernetes_cluster.personal_kubernetes_cluster.urn,
    digitalocean_database_cluster.personal_database_cluster.urn,
    digitalocean_loadbalancer.personal_kubernetes_ingress_loadbalancer.urn
  ]
}

resource "digitalocean_kubernetes_cluster" "personal_kubernetes_cluster" {
  name    = "personal"
  region  = "nyc1"
  version = "1.26.3-do.0"

  node_pool {
    name       = "worker-pool"
    size       = "s-1vcpu-2gb"
    node_count = 1
  }
}

resource "digitalocean_database_cluster" "personal_database_cluster" {
  name       = "personal"
  engine     = "pg"
  version    = "15"
  size       = "db-s-1vcpu-1gb"
  region     = "nyc1"
  node_count = 1
}

resource "digitalocean_loadbalancer" "personal_kubernetes_ingress_loadbalancer" {
  name      = "personal"
  region    = "nyc1"
  size      = "lb-small"
  algorithm = "round_robin"

  forwarding_rule {
    entry_port      = 80
    entry_protocol  = "http"
    target_port     = 80
    target_protocol = "http"

  }

  # Configuration is managed in kubernetes so we ignore all changes after initial creation
  lifecycle {
    ignore_changes = [
      forwarding_rule,
    ]
  }

}

#####################################
# Albumranker resources 
#####################################
resource "digitalocean_domain" "albumranker_domain" {
  name = "albumranker.com"
}

resource "digitalocean_record" "albumranker_a_record" {
  domain = "albumranker.com"
  type   = "A"
  ttl    = 60
  name   = "@"
  value  = digitalocean_loadbalancer.personal_kubernetes_ingress_loadbalancer.ip
  depends_on = [
    digitalocean_domain.albumranker_domain,
    kubernetes_ingress.personal_kubernetes_ingress_loadbalancer
  ]
}

resource "digitalocean_database_db" "personal_database_albumranker" {
  cluster_id = digitalocean_database_cluster.personal_database_cluster.id
  name       = "albumranker"
}

