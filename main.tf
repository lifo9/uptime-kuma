terraform {
  backend "s3" {
    bucket = "terraform-filo-state-bucket"
    key    = "uptime-kuma/terraform.tfstate"
    region = "eu-central-1"

    dynamodb_table = "terraform-filo-state-locks"
    encrypt        = true
  }

  required_providers {
    fly = {
      source = "fly-apps/fly"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

provider "fly" {
  useinternaltunnel    = true
  internaltunnelorg    = "personal"
  internaltunnelregion = var.region
}

resource "fly_app" "app" {
  name = var.app_name
}

resource "fly_ip" "ip" {
  app  = fly_app.app.name
  type = "v4"
}

resource "fly_cert" "cert" {
  app      = fly_app.app.name
  hostname = var.domain_name
}

resource "fly_volume" "data" {
  name   = "data"
  app    = fly_app.app.name
  size   = 1
  region = var.region
}

resource "fly_machine" "app" {
  app      = fly_app.app.name
  region   = var.region
  name     = var.app_name
  cputype  = "shared"
  cpus     = 1
  memorymb = 256
  image    = "registry-1.docker.io/louislam/uptime-kuma:latest"
  services = [
    {
      ports = [
        {
          port     = 443
          handlers = ["tls", "http"]
        }
      ]
      protocol : "tcp",
      internal_port : 3001
    }
  ]
  mounts = [
    {
      volume : "${fly_volume.data.name}"
      path : "/app/data"
      encrypted : true
      size_gb : fly_volume.data.size
    }
  ]
  env = {}
}

data "cloudflare_zones" "domain" {
  filter {
    name = var.zone_name
  }
}

resource "cloudflare_record" "verification_dns" {
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  name    = fly_cert.cert.dnsvalidationhostname
  value   = fly_cert.cert.dnsvalidationtarget
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_record" "domain" {
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  name    = var.domain_name
  value   = fly_ip.ip.address
  type    = "A"
  proxied = true
}
