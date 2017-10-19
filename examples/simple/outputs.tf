output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = ["${module.network.private_subnets}"]
}

output "nat_ips" {
  description = "The list of public ips of the NAT Gateways"
  value       = "${module.network.nat_public_ips}"
}
