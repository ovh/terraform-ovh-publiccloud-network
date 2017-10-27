## This example requires that you already have attached your openstack project
## your OVH Vrack

provider "ovh" {
  endpoint = "ovh-eu"
}

# Import Keypair
resource "openstack_compute_keypair_v2" "keypair" {
  name       = "my-keypair"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

module "network" {
  source = "../.."

  project_id      = "${var.project_id}"
  attach_vrack    = false
  name            = "mynetwork"
  cidr            = "10.1.0.0/16"
  region          = "SBG3"
  public_subnets  = ["10.1.0.0/24"]
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  nat_as_bastion     = true

  ssh_public_keys = ["${openstack_compute_keypair_v2.keypair.public_key}"]

  metadata = {
    Terraform   = "true"
    Environment = "Dev"
  }
}

resource "openstack_networking_port_v2" "port_private_instance" {
  name           = "port_private_instance"
  network_id     = "${module.network.network_id}"
  admin_state_up = "true"

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
