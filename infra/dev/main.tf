data "digitalocean_image" "latest_snapshot_dev" {
    name = "packer-1573955589"
}

resource "digitalocean_droplet" "dev" {
    image = data.digitalocean_image.latest_snapshot_dev.id
    name = "mockserver_api_dev"
    region = "nyc1"
    size = "s-1vcpu-1gb"
}
