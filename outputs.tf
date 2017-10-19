output "nat_security_group_id" {
  description = "The id of the security group attached to the nat instances. It can be used to later attach rules."
  value       = "${openstack_networking_secgroup_v2.nat_sg.id}"
}

output "public_subnets" {
  description = "The ids of the newly created public subnets within the network"
  value       = ["${openstack_networking_subnet_v2.public_subnets.*.id}"]
}

output "private_subnets" {
  description = "The ids of the newly created private subnets within the network"
  value       = ["${openstack_networking_subnet_v2.private_subnets.*.id}"]
}

output "nat_private_ips" {
  description = "The list of private ips of the nat gateways"
  value       = ["${openstack_networking_port_v2.port_nats.*.fixed_ip.0.ip_address}"]
}

output "nat_public_ips" {
  description = "The list of public ips of the nat gateways"
  value       = ["${openstack_compute_instance_v2.nats.*.access_ip_v4}"]
}
