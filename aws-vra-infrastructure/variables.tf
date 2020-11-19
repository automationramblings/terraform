variable "region" {
  type    = string
  default = "us-east-1"
}

variable "custom_tags" {
  type        = map(string)
  description = "Add additional tags to your resource"
  default     = {}
}

variable "ami" {
  type    = string
  default = "ami-07c5e7fdb708b7357"
}


## Availablility zones for VPC
variable "subnet_numbers" {
  description = "Map availability zone to subnet numbers"
  default = {
    "us-east-1a" = 1
    "us-east-1b" = 2
    #    "us-east-1b" = 2
  }
}
