# Container registries cannot be added to a DO project and their names must
# be universally unique.
resource "digitalocean_container_registry" "personal" {
  name                   = "nfadili_personal"
  subscription_tier_slug = "starter"
}
