variable "region" {
    type = string
    default="us-east-1"
}

variable "access_key" {
    type = string
}

variable "secret_key" {
    type = string
}

variable "ami" {
    type = string
    default="ami-07c5e7fdb708b7357"
}

variable "vra_refresh_token" {
    type = string
}

variable "vra_url" {
    type = string
}

## Availablility zones for VPC
variable "subnet_numbers" {
  description ="Map availability zone to subnet numbers"
  default = {
    "us-east-1a" = 1
    "us-east-1b" = 2
#    "us-east-1b" = 2
  }
}
