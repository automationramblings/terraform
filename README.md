<h1>vRA Data Center on Demand with Terraform</h1>

Terraform file will create AWS VPC infrastructure and configure the corresponding vRA 8.x constructs.

AWS availability zones are a variable mapping so all subnets, route tables, security groups are dynamically generated based on 1..n AZ's

vRA cloud account, images, flavors configured.  Network profiles and cloud zones dynamicaly configured driven by the 1..n AZ's mapping

<h5>Known Issues:</h5> 
<ul>
	<li>Security groups not being set properly on the network profiles</li>
    <li>How to add tags to the discovered compute resources so automatically mapped to the cloud zones?</li>
</ul>