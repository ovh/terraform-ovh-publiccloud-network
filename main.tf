## NOTE: Neutron DHCP Agents will be given an IP withtin
## the allocation pools of their associated subnet.
## If you want to fix an IP, you then have to chose one outside
## the subnet allocation pools.

## Here, we will create what we call public subnets in which
## each instance that can be reached through the internet
## should be attached to. (e.g. NATs, LBs, Bastion hosts, ...)
## The nat gw will be fixed to the 2nd ip (usually .1) of the subnets
## and the allocation pools will start at the 3rd ip (usually .2)
locals {
  re_cap_cidr_block  = "/[^/]*/([0-9]*)$/"
  network_cidr_block = "${replace(var.cidr, local.re_cap_cidr_block, "$1")}"
}

provider "openstack" {
  alias  = "${var.region}"
  region = "${var.region}"
}

resource "ovh_vrack_publiccloud_attachment" "attach" {
  count      = "${var.network_id == "" ? 1 : 0}"
  vrack_id   = "${var.vrack_id}"
  project_id = "${var.project_id}"
}

# NOTE: you won't be able to set a vlan id/segmentation id through the openstack
# API, you may want to have a look at the multiregion example to see how
# you can bootstrap cross regions networks
resource "openstack_networking_network_v2" "net" {
  provider = "openstack.${var.region}"

  count          = "${var.network_id == "" ? 1 : 0}"
  name           = "${var.name}"
  admin_state_up = "true"
  depends_on     = ["ovh_vrack_publiccloud_attachment.attach"]
}

resource "openstack_networking_secgroup_v2" "nat_sg" {
  provider = "openstack.${var.region}"

  name        = "${var.name}_nat_sg"
  description = "${var.name} security group for nat instances"
}

resource "openstack_networking_secgroup_rule_v2" "in_icmp" {
  provider = "openstack.${var.region}"

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "${var.cidr}"
  security_group_id = "${openstack_networking_secgroup_v2.nat_sg.id}"
}

resource "openstack_networking_secgroup_rule_v2" "in_tcp" {
  provider = "openstack.${var.region}"

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_ip_prefix  = "${var.cidr}"
  security_group_id = "${openstack_networking_secgroup_v2.nat_sg.id}"
}

resource "openstack_networking_secgroup_rule_v2" "in_udp" {
  provider = "openstack.${var.region}"

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  remote_ip_prefix  = "${var.cidr}"
  security_group_id = "${openstack_networking_secgroup_v2.nat_sg.id}"
}

resource "openstack_networking_subnet_v2" "public_subnets" {
  provider = "openstack.${var.region}"

  count = "${length(var.public_subnets)}"

  name       = "${var.name}_public_subnet_${count.index}"
  network_id = "${element(coalescelist(openstack_networking_network_v2.net.*.id, list(var.network_id)), 0)}"
  cidr       = "${var.public_subnets[count.index]}"
  ip_version = 4

  # dhcp is required if you want to be able to retrieve metadata from
  # the 169.254.169.254 because the route is pushed via dhcp
  enable_dhcp = true

  # this attribute is set for doc purpose only : GW are not used within OVH
  # network as it's a layer 3 network. Instead, you have to setup your
  # routes properly on each VM. see nat's ignition config for an example
  no_gateway = true

  dns_nameservers = "${var.dns_nameservers}"

  allocation_pools {
    start = "${cidrhost(var.public_subnets[count.index],2)}"
    end   = "${cidrhost(var.public_subnets[count.index],-2)}"
  }
}

resource "openstack_networking_subnet_v2" "private_subnets" {
  provider = "openstack.${var.region}"

  count      = "${length(var.private_subnets)}"
  name       = "${var.name}_subnet_${count.index}"
  network_id = "${element(coalescelist(openstack_networking_network_v2.net.*.id, list(var.network_id)), 0)}"
  cidr       = "${element(var.private_subnets, count.index)}"
  ip_version = 4

  # dhcp is required if you want to be able to retrieve metadata from
  # the 169.254.169.254 because the route is pushed via dhcp
  enable_dhcp = true

  # this attribute is set for doc purpose only : GW are not used within OVH
  # network as it's a layer 3 network. Instead, you have to setup your
  # routes properly on each VM. see nat's ignition config for an example
  no_gateway = true

  dns_nameservers = "${var.dns_nameservers}"

  allocation_pools {
    start = "${cidrhost(var.private_subnets[count.index],2)}"
    end   = "${cidrhost(var.private_subnets[count.index],-2)}"
  }

  host_routes {
    destination_cidr = "0.0.0.0/0"
    next_hop         = "${element(openstack_networking_port_v2.port_nats.*.fixed_ip.0.ip_address, count.index)}"
  }
}

resource "openstack_networking_port_v2" "port_nats" {
  provider = "openstack.${var.region}"

  count = "${var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnets)) : 0}"

  name       = "${var.name}_port_nat_${count.index}"
  network_id = "${element(coalescelist(openstack_networking_network_v2.net.*.id, list(var.network_id)), 0)}"

  admin_state_up = "true"

  security_group_ids = ["${openstack_networking_secgroup_v2.nat_sg.id}"]

  fixed_ip {
    subnet_id  = "${element(openstack_networking_subnet_v2.public_subnets.*.id, count.index)}"
    ip_address = "${cidrhost(var.public_subnets[count.index], 1)}"
  }
}

# ovh actual coreos stable version requires ignition v0.1.0
provider "ignition" {
  version = "0.1.0"
}

# as of today, networks get a dhcp route on 0.0.0.0/0 which could conflicts with pub networks routes
# set route metric to 2048 in order to privilege eth0 default routes (with a default metric of 1024) over eth1
## also enables ip forward to act as a nat
data "ignition_networkd_unit" "nat_eth1" {
  count = "${var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnets)) : 0}"
  name  = "20-eth1.network"

  ## Address is set with the global network CIDR block
  ## will ensure broadcast address to be set for the global network.
  ## (e.g.: 10.0.0.1/24 with broadcast 10.0.0.255 -> 10.0.0.1/16 with broadcast 10.0.255.255)
  content = <<IGNITION
[Match]
Name=eth1
[Network]
DHCP=ipv4
IPForward=ipv4
IPMasquerade=yes
[Route]
Destination=${var.cidr}
GatewayOnLink=yes
RouteMetric=3
Scope=link
Protocol=kernel
Source=${cidrhost(var.public_subnets[count.index], 1)}
[DHCP]
RouteMetric=2048
[Address]
Address=${format("%s/%s", cidrhost(var.public_subnets[count.index], 1), local.network_cidr_block)}
Scope=global
IGNITION
}

data "ignition_networkd_unit" "nat_eth0" {
  name = "10-eth0.network"

  content = <<IGNITION
[Match]
Name=eth0
[Network]
DHCP=ipv4
[DHCP]
RouteMetric=1024
IGNITION
}

data "ignition_user" "core" {
  name                = "core"
  ssh_authorized_keys = ["${var.nat_ssh_public_keys}"]
}

data "ignition_config" "nat" {
  count = "${var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnets)) : 0}"

  networkd = ["${data.ignition_networkd_unit.nat_eth0.id}", "${element(data.ignition_networkd_unit.nat_eth1.*.id, count.index)}"]
  users    = ["${data.ignition_user.core.*.id}"]
}

# nat instances are coreos boxes. meaning they will auto restart whenever an update
# on the stable channel will be made. (e.g.: security patches).
# this could lead to broken internet link during reboot phase.
# it could be disabled by a specific ignition setup, but it is also
# wise to benefit security updates on this kind of service instances.
# here we chose to suffer intermittent internet broken link.
resource "openstack_compute_instance_v2" "nats" {
  count = "${var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnets)) : 0}"

  provider = "openstack.${var.region}"

  name        = "${var.name}_nat_gw_${count.index}"
  image_name  = "CoreOS Stable"
  flavor_name = "${lookup(var.nat_instance_flavor_names, var.region)}"
  user_data   = "${element(data.ignition_config.nat.*.rendered,count.index)}"

  # keep netwokrs in this order so that ext-net is set on eth0
  network {
    name           = "${lookup(var.ovh_pub_nets, var.region)}"
    access_network = true
  }

  network {
    port = "${element(openstack_networking_port_v2.port_nats.*.id, count.index)}"
  }

  metadata = "${var.metadata}"
}
