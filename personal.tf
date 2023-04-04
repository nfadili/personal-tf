#####################################
# Shared/core resources
#####################################
resource "digitalocean_project" "personal" {
  name        = "personal"
  environment = "Development"
  resources = [
    digitalocean_kubernetes_cluster.personal_cluster.urn,
    digitalocean_database_cluster.personal_database_cluster.urn
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

  project_id = digitalocean_project.personal.id
}

#####################################
# Albumranker resources 
#####################################
resource "digitalocean_database_db" "personal_database_albumranker" {
  cluster_id = digitalocean_database_cluster.personal_database_cluster.id
  name       = "albumranker"
}
