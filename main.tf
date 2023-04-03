# Container registries cannot be added to a DO project but the name will match
resource "digitalocean_container_registry" "personal" {
  name                   = "personal"
  subscription_tier_slug = "starter"
}
