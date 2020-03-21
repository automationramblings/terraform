### Provider Setup
provider "aws" {
  region  = var.region
  version = "~> 2.53"
}

provider "vra" {
  url           = var.vra_url
  refresh_token = var.vra_refresh_token
  insecure = true
}

data "vra_zone"  "aws" {
  ## TBD need to figure out filter for non-existent zones
  for_each = var.subnet_numbers
  name        = join(" ", ["AWS",each.key]) 
}

data "vra_zone"  "lab" {
  name        = "vcsa.domain.local / Datacenter" 
}

locals {
  # Convert single data object in to an array
  vra_zone_lab_array=[data.vra_zone.lab]

  # Concatenate the dynamic AWS zones and the static lab vcenter zone
  vra_zone_all=concat(values(data.vra_zone.aws)[*],local.vra_zone_lab_array)

  # Variable containing list to configure allowing for delete of AWS dynamic zones
  vra_zone_configure=var.nuke == "yes" ? local.vra_zone_lab_array : local.vra_zone_all
}


resource "vra_project" "lab" {
  name        = "AWS Developer"
  description = "Project managed by terraform."
  administrators=["trent"]
  dynamic "zone_assignments" {
    for_each= local.vra_zone_configure 
    content {
      zone_id       = zone_assignments.value["id"]
    }
  }
}

