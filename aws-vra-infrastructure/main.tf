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

###################################
### AWS Datacenter confiugure   ###
###################################

resource "aws_vpc" "webapp-vpc"  {
  cidr_block="172.31.0.0/16"
  enable_dns_hostnames=true
  tags = {
    Name = "webapp-vpc"
  }
}

##  Web subnets
resource "aws_subnet" "web_subnets" {
  # iterate thru the availability zones to subnet number mapping
  for_each = var.subnet_numbers

  vpc_id     = aws_vpc.webapp-vpc.id
  cidr_block = cidrsubnet(aws_vpc.webapp-vpc.cidr_block,8,each.value)
  availability_zone = each.key
  map_public_ip_on_launch=true
  tags = {
    # used the subsring on naming to extract the last 2 chars of az for name spec (ie: web-1a)
    Name = join ("-",["web",substr(each.key,8,9)])
    Application="webapp"
    Tier="web"
    Index=each.value
  }
}

##  App subnets
resource "aws_subnet" "app_subnets" {
  for_each = var.subnet_numbers

  vpc_id     = aws_vpc.webapp-vpc.id
  cidr_block = cidrsubnet(aws_vpc.webapp-vpc.cidr_block,8,(100+each.value))
  availability_zone = each.key
  map_public_ip_on_launch=true
  tags = {
    Name = join ("-",["app",substr(each.key,8,9)])
    Application="webapp"
    Tier="app"
    Index=each.value
  }
}

### IGW 

resource "aws_internet_gateway" "webapp-igw" {
  vpc_id=aws_vpc.webapp-vpc.id
  tags = {
    Name = "webapp-igw"
  }
}


### Route tables and associations
resource "aws_route_table" "webapp-rt" {
  vpc_id= aws_vpc.webapp-vpc.id
  route {
    cidr_block="0.0.0.0/0"
    gateway_id=aws_internet_gateway.webapp-igw.id
  }
  tags = {
    Name = "webapp-rt"
  }
}

resource "aws_route_table_association" "web_routes" {
  for_each = aws_subnet.web_subnets
  subnet_id=each.value["id"]
  route_table_id=aws_route_table.webapp-rt.id
}

resource "aws_route_table_association" "app_routes" {
  for_each = aws_subnet.app_subnets
  subnet_id=each.value["id"]
  route_table_id=aws_route_table.webapp-rt.id
}


# Security Groups for web tier
resource "aws_security_group" "web-sg" {
  vpc_id= aws_vpc.webapp-vpc.id
  description="web-sg"
  name="web-sg"
  tags = {
    Name = "web-sg"
  }
  ingress {
    description = "http-80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp" 
    cidr_blocks = ["0.0.0.0/0"]   
  }
  ingress {
    description = "https-443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp" 
    cidr_blocks = ["0.0.0.0/0"]   
  }
  ingress {
    description = "http-81"
    from_port   = 81
    to_port     = 81
    protocol    = "tcp" 
    cidr_blocks = [aws_vpc.webapp-vpc.cidr_block]   
  }
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp" 
    cidr_blocks = ["0.0.0.0/0"]   
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#Create SG for app tier

resource "aws_security_group" "app-sg" {
  vpc_id= aws_vpc.webapp-vpc.id
  description="app-sg"
  name="app-sg"
  tags = {
    Name = "app-sg"
  }
  ingress {
    description = "app 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp" 
    # Iterate through the web subnets and extra the cidr_block for each to build the list for hte sg.
    cidr_blocks = [
      for subnet in aws_subnet.web_subnets: subnet.cidr_block
    ]
  }
  ingress {
    description = "secure app 8443"
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp" 
    cidr_blocks = [
      for subnet in aws_subnet.web_subnets: subnet.cidr_block
    ]
  }
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp" 
    cidr_blocks = ["0.0.0.0/0"]   
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Create SG for DB tier
resource "aws_security_group" "db-sg" {
  vpc_id= aws_vpc.webapp-vpc.id
  description="db-sg"
  name="db-sg"
  tags = {
    Name = "db-sg"
  }
  ingress {
    description = "db 3306"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp" 
    cidr_blocks = [
      for subnet in aws_subnet.app_subnets: subnet.cidr_block
    ]
  }
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp" 
    cidr_blocks = ["0.0.0.0/0"]   
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

###################################
#####  vRA Configuration       ####
###################################

resource "vra_cloud_account_aws" "lab" {
  name        = "AWS Cloud Account Lab"
  description = "AWS Cloud Account Lab configured by Terraform"
  access_key  = var.access_key
  secret_key  = var.secret_key
  regions     = [var.region]

  tags {
    key   = "location"
    value = "aws"
  } 
  provisioner "local-exec" {
    command = "sleep 10"
  }
  depends_on = [aws_route_table_association.web_routes,aws_route_table_association.app_routes]
}

# Get the vra_regoion to create the Cloud Zones
data "vra_region" "lab" {
  cloud_account_id = vra_cloud_account_aws.lab.id
  region           = var.region
}


# Configure a new Cloud Zone
resource "vra_zone" "aws" {
  for_each = var.subnet_numbers
  name        = join(" ", ["AWS",each.key]) 
  description = join(" ", ["Cloud Zone configured by Terraform",each.key])
  region_id   = data.vra_region.lab.id
  tags_to_match {
    key = "zone"
    value= each.key
  }
  tags {
    key   = "zone"
    value = each.key
  }
}

resource "vra_flavor_profile" "lab" {
  name        = "terraform-flavor-profile"
  description = "Flavor profile created by Terraform"
  region_id   = data.vra_region.lab.id
  flavor_mapping {
    name          = "small"
    instance_type = "t3a.nano" 
  }
  flavor_mapping {
    name          = "medium"
    instance_type = "t3a.micro" 
  }
  flavor_mapping {
    name          = "large"
    instance_type = "t3a.small" 
  }
}

# Create a new image profile
resource "vra_image_profile" "lab" {
  name        = "terraform-aws-image-profile"
  description = "AWS image profile created by Terraform"
  region_id   = data.vra_region.lab.id

  image_mapping {
    name       = "docker"
    image_name = var.ami
  }
}

## Get the fabric array for all discovred web subnets
data "vra_fabric_network" "web" {
  for_each=aws_subnet.web_subnets
  filter = "name eq '${each.value.tags.Name}'"
  depends_on = [vra_cloud_account_aws.lab]
}

## Get the fabric array for all discovred app subnets
data "vra_fabric_network" "app" {
  for_each=aws_subnet.app_subnets
  filter = "name eq '${each.value.tags.Name}'"
  depends_on = [vra_cloud_account_aws.lab]
}

## configure the network profiles and add cabability tags
resource  "vra_network_profile" "web" {
  name = "aws-web"
  description = "AWS Web Tier Profile"
  region_id=data.vra_region.lab.id

  fabric_network_ids = [for i in data.vra_fabric_network.web: i.id]
  security_group_ids=[aws_security_group.web-sg.id]
  isolation_type="SECURITY_GROUP"
  tags {
    key="Tier"
    value="web"
  }
}

## configure the network profiles and add cabability tags=
resource  "vra_network_profile" "app" {
  name = "aws-app"
  description = "AWS Web Tier Profile"
  region_id=data.vra_region.lab.id

  fabric_network_ids = [for i in data.vra_fabric_network.app: i.id]
  security_group_ids=[aws_security_group.app-sg.id]
  isolation_type="SECURITY_GROUP"
  tags {
    key="Tier"
    value="app"
  }
}