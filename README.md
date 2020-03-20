vRA Data Center on Demand with Terraform

Terraform file will create AWS VPC infrastructure and 
configure the corresponding vRA 8.x constructs.

AWS availability zones are a variable mapping so all subnets, route tables, security groups are dynamically generated based on 1..n AZ's

vRA cloud account, images, flavors configured.  Network profiles and cloud zones dynamicaly configured driven by the 1..n AZ's mapping

Issues:  Security groups not being set properly on the netwrok profiles
