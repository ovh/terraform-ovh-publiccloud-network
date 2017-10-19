provider "ovh" {
  endpoint = "ovh-eu"
}

provider "openstack" {
  alias  = "GRA3"
  region = "GRA3"
}

provider "openstack" {
  alias  = "DE1"
  region = "DE1"
}

provider "openstack" {
  alias  = "SBG3"
  region = "SBG3"
}

##################################################################
## the following block is necessary
## - to create all the networks with the same segmentation/vlan ID
## - retrieve corresponding openstack network id per region
##
## it will be refactored as soon as the OVH API returns
## openstack IDs instead of internal IDs. planned for end of 2017
##################################################################
resource "ovh_vrack_publiccloud_attachment" "attach" {
  vrack_id   = "${var.vrack_id}"
  project_id = "${var.project_id}"
}

# make use of the ovh api to set a vlan id (or segmentation id)
resource "ovh_publiccloud_private_network" "net" {
  project_id = "${var.project_id}"
  name       = "mynetwork"
  regions    = ["GRA3", "SBG3", "DE1"]
  vlan_id    = "100"

  depends_on = ["ovh_vrack_publiccloud_attachment.attach"]
}

# hack to retrieve openstack network id
data "openstack_networking_network_v2" "net_GRA3" {
  provider = "openstack.GRA3"

  name = "${ovh_publiccloud_private_network.net.name}"
}

data "openstack_networking_network_v2" "net_SBG3" {
  provider = "openstack.SBG3"

  name = "${ovh_publiccloud_private_network.net.name}"
}

data "openstack_networking_network_v2" "net_DE1" {
  provider = "openstack.DE1"

  name = "${ovh_publiccloud_private_network.net.name}"
}

##################################################################
## end block
##################################################################

module "network_GRA3" {
  source = "../.."

  network_id = "${data.openstack_networking_network_v2.net_GRA3.id}"

  name = "mynetwork"
  cidr = "10.0.0.0/16"

  region          = "GRA3"
  public_subnets  = ["10.0.0.0/24"]
  private_subnets = ["10.0.1.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  metadata = {
    Terraform   = "true"
    Environment = "prod"
  }
}

module "network_SBG3" {
  source = "../.."

  network_id = "${data.openstack_networking_network_v2.net_SBG3.id}"

  name = "mynetwork"
  cidr = "10.0.0.0/16"

  region          = "SBG3"
  public_subnets  = ["10.0.10.0/24"]
  private_subnets = ["10.0.11.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  metadata = {
    Terraform   = "true"
    Environment = "prod"
  }
}

module "network_DE1" {
  source = "../.."

  network_id = "${data.openstack_networking_network_v2.net_DE1.id}"

  name = "mynetwork"
  cidr = "10.0.0.0/16"

  region          = "DE1"
  public_subnets  = ["10.0.20.0/24"]
  private_subnets = ["10.0.21.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  metadata = {
    Terraform   = "true"
    Environment = "prod"
  }
}
