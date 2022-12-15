variable "app_name" {
  type    = string
  default = "filo-uptime-kuma"
}

variable "region" {
  type    = string
  default = "fra" # Frankfurt
}

variable "zone_name" {
  type    = string
  default = "filo.dev"
}

variable "domain_name" {
  type    = string
  default = "uptime.filo.dev"
}
