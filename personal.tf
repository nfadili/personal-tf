#####################################
# Shared/core Digital Ocean resources
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

  depends_on = [
    digitalocean_kubernetes_cluster.personal_kubernetes_cluster
  ]
}

#####################################
# Cluster core resources 
#####################################
resource "helm_release" "personal_nginx_ingress_controller" {
  name       = "nginx-ingress-controller"
  namespace  = "default"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx-ingress-controller"
  set {
    name  = "service.type"
    value = "LoadBalancer"
  }
  set {
    name  = "service.annotations.kubernetes\\.digitalocean\\.com/load-balancer-id"
    value = digitalocean_loadbalancer.personal_kubernetes_ingress_loadbalancer.id
  }
  depends_on = [
    digitalocean_loadbalancer.personal_kubernetes_ingress_loadbalancer,
  ]
}



resource "helm_release" "personal_certmanager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.11.0"
  namespace  = "kube-system"
  timeout    = 120
  depends_on = [
    helm_release.personal_nginx_ingress_controller,
  ]
  set {
    name  = "createCustomResource"
    value = "true"
  }
  set {
    name  = "installCRDs"
    value = "true"
  }
}

# TODO: Figure out if we should apply the ClusterIssuer manifest here in terraform or alongside other kubernetes resources
# https://stackoverflow.com/questions/68511476/setup-letsencrypt-clusterissuer-with-terraform
# - Applying here would require the cluster to already be created before applying
# - Applying with other kubernetes resources put the onus on the app deployment to manager cert issuing


#####################################
# Albumranker resources 
#####################################
resource "kubernetes_namespace" "albumranker_namespace" {
  metadata {
    name = "albumranker"
  }
}

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
    kubernetes_ingress.albumranker_ingress
  ]
}

resource "kubernetes_ingress" "albumranker_ingress" {
  depends_on = [
    helm_release.personal_nginx_ingress_controller,
  ]
  metadata {
    name      = "albumranker-ingress"
    namespace = kubernetes_namespace.albumranker_namespace.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"          = "nginx"
      "ingress.kubernetes.io/rewrite-target" = "/"
      "cert-manager.io/cluster-issuer"       = "letsencrypt-production"
    }
  }
  spec {
    rule {
      host = "albumranker.com"
      http {
        path {
          path = "/"
          backend {
            service_name = "albumranker-com-service"
            service_port = 80
          }
        }
      }
    }
    tls {
      secret_name = "albumranker-com-tls"
      hosts = [
        "albumranker.com"
      ]
    }
  }
}

resource "digitalocean_database_db" "personal_database_albumranker" {
  cluster_id = digitalocean_database_cluster.personal_database_cluster.id
  name       = "albumranker"
}

