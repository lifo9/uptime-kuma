terraform {
  backend "s3" {
    bucket = "terraform-filo-state-bucket"
    key    = "uptime-kuma/terraform.tfstate"
    region = "eu-central-1"

    dynamodb_table = "terraform-filo-state-locks"
    encrypt        = true
  }

  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

data "cloudflare_zones" "domain" {
  filter {
    name = var.zone_name
  }
}

resource "cloudflare_record" "verification_dns" {
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  name    = var.dns_validation_hostname
  value   = var.dns_validation_target
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_record" "domain" {
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  name    = var.domain_name
  value   = var.cname
  type    = "CNAME"
  proxied = true
}
