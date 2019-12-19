data "digitalocean_image" "latest_snapshot_dev" {
    name = "packer-1576793043"
}

resource "digitalocean_droplet" "dev" {
    image = data.digitalocean_image.latest_snapshot_dev.id
    name = "mockserver-api-dev"
    region = "nyc1"
    size = "s-1vcpu-1gb"
}
