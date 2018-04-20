## NOTE: Neutron DHCP Agents will be given an IP withtin
## the allocation pools of their associated subnet.
## If you want to fix an IP, you then have to chose one outside
## the subnet allocation pools.

## Here, we will create what we call public subnets in which
## each instance that can be reached through the internet
## should be attached to. (e.g. NATs, LBs, Bastion hosts, ...)
## - the 2nd ip will be reserved for nat gateways (usually .1)
## - the allocation pools will start at the 3rd ip (usually .2)
terraform {
  required_version = ">= 0.11.0"
}

locals {
  nb_nats            = "${var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.private_subnets)) : 0}"
  re_cap_cidr_block  = "/[^/]*/([0-9]*)$/"
  network_cidr_block = "${replace(var.cidr, local.re_cap_cidr_block, "$1")}"
  nat_ssh_keys       = "${compact(split(",", var.nat_as_bastion && var.enable_nat_gateway && length(var.ssh_public_keys) > 0 ? join(",", var.ssh_public_keys) : ""))}"
  network_id         = "${element(coalescelist(openstack_networking_network_v2.net.*.id, data.openstack_networking_network_v2.preexisting_net.*.id), 0)}"
}

data "openstack_networking_network_v2" "ext_net" {
  name      = "${lookup(var.ovh_pub_nets, var.region, var.default_ovh_pub_net)}"
  tenant_id = ""
}

data "openstack_networking_network_v2" "preexisting_net" {
  count      = "${var.create_network ? 0 : 1}"
  name       = "${var.network_name}"
  network_id = "${var.network_id}"
}

resource "openstack_networking_network_v2" "net" {
  count          = "${var.create_network ? 1 : 0}"
  name           = "${var.name}"
  admin_state_up = "true"
}

resource "openstack_networking_secgroup_v2" "nat_sg" {
  name        = "${var.name}_nat_sg"
  description = "${var.name} security group for nat instances"
}

resource "openstack_networking_secgroup_rule_v2" "in_icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "${var.cidr}"
  security_group_id = "${openstack_networking_secgroup_v2.nat_sg.id}"
}

resource "openstack_networking_secgroup_rule_v2" "in_tcp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_ip_prefix  = "${var.cidr}"
  security_group_id = "${openstack_networking_secgroup_v2.nat_sg.id}"
}

resource "openstack_networking_secgroup_rule_v2" "in_udp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  remote_ip_prefix  = "${var.cidr}"
  security_group_id = "${openstack_networking_secgroup_v2.nat_sg.id}"
}

resource "openstack_networking_secgroup_rule_v2" "nat_in_ssh" {
  count = "${var.nat_as_bastion ? 1  : 0 }"

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.nat_sg.id}"
}

resource "openstack_networking_secgroup_v2" "bastion_sg" {
  name        = "${var.name}_bastion_sg"
  description = "${var.name} security group for bastion hosts"
}

resource "openstack_networking_secgroup_rule_v2" "bastion_in_ssh" {
  count = "${var.enable_bastion_host ? 1  : 0 }"

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.bastion_sg.id}"
}

resource "openstack_networking_subnet_v2" "public_subnets" {
  count = "${length(var.public_subnets)}"

  name       = "${var.name}_public_subnet_${count.index}"
  network_id = "${local.network_id}"
  cidr       = "${var.public_subnets[count.index]}"
  ip_version = 4

  # dhcp is required if you want to be able to retrieve metadata from
  # the 169.254.169.254 because the route is pushed via dhcp
  enable_dhcp = true

  # this attribute is set for doc purpose only : GW are not used within OVH
  # network as it's a layer 3 network. Instead, you have to setup your
  # routes properly on each VM. see nat's ignition config for an example
  no_gateway = true

  dns_nameservers = ["${var.dns_nameservers}"]

  allocation_pools {
    start = "${cidrhost(var.public_subnets[count.index],2)}"
    end   = "${cidrhost(var.public_subnets[count.index],-2)}"
  }
}

resource "openstack_networking_subnet_v2" "nat_private_subnets" {
  count      = "${var.enable_nat_gateway ? length(var.private_subnets) : 0}"
  name       = "${var.name}_subnet_${count.index}"
  network_id = "${local.network_id}"
  cidr       = "${element(var.private_subnets, count.index)}"
  ip_version = 4

  # dhcp is required if you want to be able to retrieve metadata from
  # the 169.254.169.254 because the route is pushed via dhcp
  enable_dhcp = true

  # this attribute is set for doc purpose only : GW are not used within OVH
  # network as it's a layer 3 network. Instead, you have to setup your
  # routes properly on each VM. see nat's ignition config for an example
  no_gateway = true

  dns_nameservers = ["${var.dns_nameservers}"]

  allocation_pools {
    # dhcp agents will take an ip at the beginning of the allocation pool
    start = "${cidrhost(var.private_subnets[count.index],2)}"
    end   = "${cidrhost(var.private_subnets[count.index],-2)}"
  }

  host_routes {
    destination_cidr = "0.0.0.0/0"
    next_hop         = "${element(coalescelist(openstack_networking_port_v2.port_nats.*.fixed_ip.0.ip_address, list("dummy")), count.index)}"
  }
}

resource "openstack_networking_subnet_v2" "no_nat_private_subnets" {
  count      = "${var.enable_nat_gateway ? 0 : length(var.private_subnets)}"
  name       = "${var.name}_subnet_${count.index}"
  network_id = "${local.network_id}"
  cidr       = "${element(var.private_subnets, count.index)}"
  ip_version = 4

  # dhcp is required if you want to be able to retrieve metadata from
  # the 169.254.169.254 because the route is pushed via dhcp
  enable_dhcp = true

  # this attribute is set for doc purpose only : GW are not used within OVH
  # network as it's a layer 3 network. Instead, you have to setup your
  # routes properly on each VM. see nat's ignition config for an example
  no_gateway = true

  dns_nameservers = ["${var.dns_nameservers}"]

  allocation_pools {
    # dhcp agents will take an ip at the beginning of the allocation pool
    start = "${cidrhost(var.private_subnets[count.index],2)}"
    end   = "${cidrhost(var.private_subnets[count.index],-2)}"
  }
}

resource "openstack_networking_port_v2" "public_port_nats" {
  count = "${local.nb_nats}"

  name               = "${var.name}_public_port_nat_${count.index}"
  network_id         = "${data.openstack_networking_network_v2.ext_net.id}"
  admin_state_up     = "true"
  security_group_ids = ["${openstack_networking_secgroup_v2.nat_sg.id}"]
}

resource "openstack_networking_port_v2" "port_nats" {
  count = "${local.nb_nats}"

  name       = "${var.name}_port_nat_${count.index}"
  network_id = "${local.network_id}"

  admin_state_up = "true"

  security_group_ids = ["${openstack_networking_secgroup_v2.nat_sg.id}"]

  fixed_ip {
    subnet_id  = "${element(openstack_networking_subnet_v2.public_subnets.*.id, count.index)}"
    ip_address = "${cidrhost(var.public_subnets[count.index], 1)}"
  }
}

data "template_file" "nat_systemd_network_files" {
  count = "${local.nb_nats}"

  template = <<TPL
- path: /etc/systemd/network/10-eth0.network
  permissions: '0644'
  content: |
     ## Address is set with the global network CIDR block
     ## will ensure broadcast address to be set for the global network.
     ## (e.g.: 10.0.0.1/24 with broadcast 10.0.0.255 -> 10.0.0.1/16 with broadcast 10.0.255.255)
     [Match]
     Name=eth0
     [Network]
     DHCP=ipv4
     IPForward=ipv4
     IPMasquerade=yes
     [Route]
     Destination=${var.cidr}
     GatewayOnLink=yes
     Scope=link
     Protocol=kernel
     Source=${cidrhost(var.public_subnets[count.index], 1)}
     [Address]
     Address=${format("%s/%s", cidrhost(var.public_subnets[count.index], 1), local.network_cidr_block)}
     Scope=global
- path: /etc/systemd/network/20-eth1.network
  permissions: '0644'
  content: |
    [Match]
    Name=eth1
    [Network]
    DHCP=ipv4
TPL
}

# Render a multi-part cloudinit config making use of the part
# above, and other source files
data "template_file" "nat_userdata" {
  count = "${local.nb_nats}"

  template = <<CLOUDCONFIG
#cloud-config
ssh_authorized_keys:
  ${indent(2, join("\n", formatlist("- %s", local.nat_ssh_keys)))}
## This route has to be added in order to reach other subnets of the network
coreos:
  update:
    reboot-strategy: "off"
  units:
    - name: "restartnetwork.service"
      command: "start"
      content: |
        [Service]
        Type=oneshot
        RemainAfterExit=yes
        ExecStart=/usr/bin/systemctl restart systemd-networkd.service
write_files:
  ${indent(2, element(data.template_file.nat_systemd_network_files.*.rendered, count.index))}
CLOUDCONFIG
}

resource "openstack_compute_servergroup_v2" "nats" {
  name     = "${var.name}-nat-servergroup"
  policies = ["anti-affinity"]
}

# nat instances are coreos boxes. meaning they will auto restart whenever an update
# on the stable channel will be made. (e.g.: security patches).
# this could lead to broken internet link during reboot phase.
# it could be disabled by a specific ignition setup, but it is also
# wise to benefit security updates on this kind of service instances.
# here we chose to suffer intermittent internet broken link.
resource "openstack_compute_instance_v2" "nats" {
  count = "${local.nb_nats}"

  name        = "${var.name}_nat_gw_${count.index}"
  image_name  = "CoreOS Stable"
  flavor_name = "${var.nat_instance_flavor_name != "" ? var.nat_instance_flavor_name : lookup(var.nat_instance_flavor_names, var.region, var.default_nat_instance_flavor_name)}"
  user_data   = "${element(data.template_file.nat_userdata.*.rendered,count.index)}"
  key_pair    = "${var.key_pair}"

  # keep netwokrs in this order so that ext-net is set on eth1
  network {
    port = "${element(openstack_networking_port_v2.port_nats.*.id, count.index)}"
  }

  network {
    access_network = true
    port           = "${element(openstack_networking_port_v2.public_port_nats.*.id, count.index)}"
  }

  scheduler_hints {
    group = "${openstack_compute_servergroup_v2.nats.id}"
  }

  metadata = "${var.metadata}"
}

# This is somekind of a hack to ensure that when a private subnet id is output and made
# available to other resources outside the module, the associated NAT GW has been spawned
# thus ensuring internet connectivity.
# Otherwise, instances and nat gws maybe spawned in parallel, resulting in possible failure of
# instances cloudinit scripts that relies on internet connection
data "template_file" "private_subnets_ids" {
  count    = "${length(var.private_subnets)}"
  template = "$${private_subnet_id}"

  vars {
    nat_id            = "${element(coalescelist(openstack_compute_instance_v2.nats.*.id, list("")), count.index)}"
    private_subnet_id = "${element(coalescelist(openstack_networking_subnet_v2.nat_private_subnets.*.id, openstack_networking_subnet_v2.no_nat_private_subnets.*.id), count.index)}"
  }
}

resource "openstack_networking_port_v2" "public_port_bastion" {
  count = "${var.enable_bastion_host ? 1 : 0 }"

  name               = "${var.name}_bastion_public_port"
  network_id         = "${data.openstack_networking_network_v2.ext_net.id}"
  admin_state_up     = "true"
  security_group_ids = ["${openstack_networking_secgroup_v2.bastion_sg.id}"]
}

resource "openstack_networking_port_v2" "port_bastion" {
  count = "${var.enable_bastion_host ? 1 : 0 }"

  name               = "${var.name}_bastion_port"
  network_id         = "${local.network_id}"
  admin_state_up     = "true"
  security_group_ids = ["${openstack_networking_secgroup_v2.bastion_sg.id}"]

  fixed_ip {
    subnet_id = "${element(openstack_networking_subnet_v2.public_subnets.*.id, 0)}"
  }
}

data "template_file" "bastion_systemd_network_files" {
  template = <<TPL
- path: /etc/systemd/network/10-eth0.network
  permissions: '0644'
  content: |
     [Match]
     Name=eth0
     [Network]
     DHCP=ipv4
     [Route]
     Destination=${var.cidr}
     GatewayOnLink=yes
     Scope=link
     Protocol=kernel
- path: /etc/systemd/network/20-eth1.network
  permissions: '0644'
  content: |
    [Match]
    Name=eth1
    [Network]
    DHCP=ipv4
TPL
}

# Render a multi-part cloudinit config making use of the part
# above, and other source files
data "template_file" "bastion_userdata" {
  template = <<CLOUDCONFIG
#cloud-config
ssh_authorized_keys:
  ${indent(2, join("\n", formatlist("- %s", local.nat_ssh_keys)))}
## This route has to be added in order to reach other subnets of the network
coreos:
  update:
    reboot-strategy: "off"
  units:
    - name: "restartnetwork.service"
      command: "start"
      content: |
        [Service]
        Type=oneshot
        RemainAfterExit=yes
        ExecStart=/usr/bin/systemctl restart systemd-networkd.service
write_files:
  ${indent(2, data.template_file.bastion_systemd_network_files.rendered)}
CLOUDCONFIG
}

resource "openstack_compute_instance_v2" "bastion" {
  count = "${var.enable_bastion_host ? 1 : 0 }"

  name        = "${var.name}_bastion"
  image_name  = "CoreOS Stable"
  flavor_name = "${var.bastion_instance_flavor_name != "" ? var.bastion_instance_flavor_name : lookup(var.bastion_instance_flavor_names, var.region, var.default_bastion_instance_flavor_name)}"
  key_pair    = "${var.key_pair}"

  user_data = "${data.template_file.bastion_userdata.rendered}"

  # keep netwokrs in this order so that ext-net is set on eth1
  network {
    port = "${openstack_networking_port_v2.port_bastion.id}"
  }

  network {
    access_network = true
    port           = "${openstack_networking_port_v2.public_port_bastion.id}"
  }

  metadata = "${var.metadata}"
}
