terraform {
  required_version = ">=0.12.0"
}

data "digitalocean_image" "latest_snapshot_dev" {
  name = "apiserver-1578270436"
}

data "digitalocean_image" "latest_database_dev" {
  name = "database-1577063166"
}

resource "digitalocean_project" "mimo_dev" {
  name        = "mimo_dev"
  environment = "Development"
  resources = [
    digitalocean_volume.dev_database.urn,
    digitalocean_domain.mimo_internal.urn,
    digitalocean_droplet.mimo_api_dev.urn,
    digitalocean_droplet.mimo_database_dev.urn,
    digitalocean_floating_ip.mimo_api.urn
  ]
}

resource "digitalocean_domain" "mimo_internal" {
  name = "internal.mimo"
}

resource "digitalocean_record" "dev_database" {
  domain = digitalocean_domain.mimo_internal.name
  type   = "A"
  name   = "db"
  value  = digitalocean_droplet.mimo_database_dev.ipv4_address_private
}

resource "digitalocean_record" "dev_api" {
  domain = digitalocean_domain.mimo_internal.name
  type   = "A"
  name   = "api"
  value  = digitalocean_droplet.mimo_api_dev.ipv4_address_private
}

resource "digitalocean_domain" "ldelelis_dev" {
  name = "ldelelis.dev"
}

resource "digitalocean_record" "dev_access_api" {
  domain = digitalocean_domain.ldelelis_dev.name
  type   = "A"
  name   = "dev.mimo"
  value  = digitalocean_floating_ip.mimo_api.ip_address
  ttl    = 60
}

resource "digitalocean_volume" "dev_database" {
  region = "nyc1"
  name   = "dev-db"
  size   = 1
}

resource "digitalocean_firewall" "dev_database" {
  name = "only-5432"
  droplet_ids = [
    digitalocean_droplet.mimo_database_dev.id
  ]
  inbound_rule {
    protocol   = "tcp"
    port_range = "5432"
    source_droplet_ids = [
      digitalocean_droplet.mimo_api_dev.id
    ]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "53"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol   = "tcp"
    port_range = "5432"
    destination_droplet_ids = [
      digitalocean_droplet.mimo_api_dev.id
    ]
  }
  outbound_rule {
    protocol              = "tcp"
    port_range            = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

resource "digitalocean_floating_ip" "mimo_api" {
  droplet_id = digitalocean_droplet.mimo_api_dev.id
  region     = digitalocean_droplet.mimo_api_dev.region
}

resource "digitalocean_droplet" "mimo_api_dev" {
  image  = data.digitalocean_image.latest_snapshot_dev.id
  name   = "mimo-api-dev"
  region = "nyc1"
  size   = "s-1vcpu-1gb"
  ssh_keys = [
    var.digitalocean_ssh_name
  ]
  private_networking = true

  connection {
    type        = "ssh"
    private_key = file("/home/blanc/.ssh/id_ed25519")
    host        = self.ipv4_address
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rsync -ralvz -e 'ssh -o ConnectionAttempts=10 -o StrictHostKeyChecking=no' root@${self.ipv4_address}:/etc/letsencrypt ../../images/."
  }
}

resource "digitalocean_droplet" "mimo_database_dev" {
  image  = data.digitalocean_image.latest_database_dev.id
  name   = "mimo-database-dev"
  region = "nyc1"
  size   = "s-1vcpu-1gb"
  ssh_keys = [
    var.digitalocean_ssh_name
  ]
  volume_ids = [
    digitalocean_volume.dev_database.id
  ]
  private_networking = true

  provisioner "remote-exec" {
    when = create
    inline = [
      "mount /dev/sda /mnt",
      "pg_ctlcluster 10 main stop",
      "rm /var/lib/postgresql/10/main -rf",
      "ln -s /mnt /var/lib/postgresql/10/main",
      "pg_ctlcluster 10 main start"
    ]
  }
}
