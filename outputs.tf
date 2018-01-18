output "nat_security_group_id" {
  description = "The id of the security group attached to the nat instances. It can be used to later attach rules."
  value       = "${openstack_networking_secgroup_v2.nat_sg.id}"
}

output "bastion_security_group_id" {
  description = "The id of the security group attached to the bastion hosts. It can be used to later attach rules."
  value       = "${openstack_networking_secgroup_v2.nat_sg.id}"
}

output "network_id" {
  description = "The id of the network."
  value       = "${local.network_id}"
}

output "public_subnets" {
  description = "The ids of the newly created public subnets within the network"
  value       = ["${openstack_networking_subnet_v2.public_subnets.*.id}"]
}

output "private_subnets" {
  description = "The ids of the newly created private subnets within the network"
  value       = ["${data.template_file.private_subnets_ids.*.rendered}"]
}

output "nat_private_ips" {
  description = "The list of private ips of the nat gateways"
  value       = ["${flatten(openstack_networking_port_v2.port_nats.*.all_fixed_ips)}"]
}

output "nat_public_ips" {
  description = "The list of public ips of the nat gateways"
  value       = ["${openstack_compute_instance_v2.nats.*.access_ip_v4}"]
}

output "bastion_public_ip" {
  description = "The public ip of the bastion host"
  value       = "${join("", coalescelist(openstack_compute_instance_v2.bastion.*.access_ip_v4, openstack_compute_instance_v2.nats.*.access_ip_v4))}"
}
