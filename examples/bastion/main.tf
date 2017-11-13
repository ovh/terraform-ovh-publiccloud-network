provider "ovh" {
  endpoint = "ovh-eu"
}

provider "openstack" {
  region = "${var.region}"
}

# Import Keypair
resource "openstack_compute_keypair_v2" "keypair" {
  name       = "my-keypair"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

module "network" {
  source = "ovh/publiccloud-network/ovh"

  project_id      = "${var.project_id}"
  vrack_id        = "${var.vrack_id}"
  name            = "mynetwork"
  cidr            = "10.0.0.0/16"
  region          = "${var.region}"
  public_subnets  = ["10.0.0.0/24", "10.0.10.0/24"]
  private_subnets = ["10.0.1.0/24", "10.0.11.0/24"]

  enable_nat_gateway  = true
  enable_bastion_host = true

  ssh_public_keys = ["${openstack_compute_keypair_v2.keypair.public_key}"]

  metadata = {
    Terraform   = "true"
    Environment = "Dev"
  }
}

resource "openstack_networking_port_v2" "port_private_instance" {
  name               = "port_private_instance"
  network_id         = "${module.network.network_id}"
  admin_state_up     = "true"

  fixed_ip {
    subnet_id = "${module.network.private_subnets[0]}"
  }
}

resource "openstack_compute_instance_v2" "my_private_instance" {
  name        = "my_private_instance"
  image_name  = "Centos 7"
  flavor_name = "s1-8"
  key_pair    = "${openstack_compute_keypair_v2.keypair.name}"

  user_data = <<USERDATA
#cloud-config
## This route has to be added in order to reach other subnets of the network
bootcmd:
  - ip route add 10.0.0.0/16 dev eth0 scope link metric 0
write_files:
  - path: /etc/sysconfig/network-scripts/route-eth0
    content: |
      10.0.0.0/16 dev eth0 scope link metric 0
USERDATA

  network {
    port = "${openstack_networking_port_v2.port_private_instance.id}"
  }
}
