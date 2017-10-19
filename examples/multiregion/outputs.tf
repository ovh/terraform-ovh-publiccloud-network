# Subnets
output "GRA3_private_subnets" {
  description = "List of IDs of private subnets"
  value       = ["${module.network_GRA3.private_subnets}"]
}
output "SBG3_private_subnets" {
  description = "List of IDs of private subnets"
  value       = ["${module.network_SBG3.private_subnets}"]
}
output "DE1_private_subnets" {
  description = "List of IDs of private subnets"
  value       = ["${module.network_DE1.private_subnets}"]
}

output "GRA3_nat_ips" {
  description = "The list of public ips of the NAT Gateways"
  value       = "${module.network_GRA3.nat_public_ips}"
}

output "SBG3_nat_ips" {
  description = "The list of public ips of the NAT Gateways"
  value       = "${module.network_SBG3.nat_public_ips}"
}

output "DE1_nat_ips" {
  description = "The list of public ips of the NAT Gateways"
  value       = "${module.network_DE1.nat_public_ips}"
}
