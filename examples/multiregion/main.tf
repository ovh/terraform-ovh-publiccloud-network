provider "ignition" {
  version = "~> 1.0"
}

provider "ovh" {
  version = "~> 0.2"
  endpoint = "ovh-eu"
}

provider "openstack" {
  version = "~> 1.2"
  alias  = "GRA3"
  region = "GRA3"
}

provider "openstack" {
  version = "~> 1.2"
  alias  = "DE1"
  region = "DE1"
}

provider "openstack" {
  version = "~> 1.2"
  alias  = "SBG3"
  region = "SBG3"
}

##################################################################
## it is required to create the network through the ovh resource
## to create all the networks with the same segmentation/vlan ID
##################################################################
resource "ovh_vrack_publiccloud_attachment" "attach" {
  count      = "${var.attach_vrack}"
  vrack_id   = "${var.vrack_id}"
  project_id = "${var.project_id}"
}

# make use of the ovh api to set a vlan id (or segmentation id)
resource "ovh_publiccloud_private_network" "net" {
  project_id = "${var.project_id}"
  name       = "${var.network_name}"
  regions    = ["GRA3", "SBG3", "DE1"]
  vlan_id    = "110"

  depends_on = ["ovh_vrack_publiccloud_attachment.attach"]
}

module "network_GRA3" {
  #  source  = "ovh/publiccloud-network/ovh"
  #  version = ">= 0.0.10"
  source = "../.."

  project_id         = "${var.project_id}"
  network_name       = "${ovh_publiccloud_private_network.net.name}"
  create_network     = false
  name               = "${var.network_name}"
  attach_vrack       = "${var.attach_vrack}"
  cidr               = "10.0.0.0/16"
  region             = "GRA3"
  public_subnets     = ["10.0.0.0/24"]
  private_subnets    = ["10.0.1.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true

  metadata = {
    Terraform   = "true"
    Environment = "prod"
  }

  providers = {
    "openstack" = "openstack.GRA3"
  }
}

module "network_SBG3" {
  #  source  = "ovh/publiccloud-network/ovh"
  #  version = ">= 0.0.10"
  source = "../.."

  project_id         = "${var.project_id}"
  network_name       = "${ovh_publiccloud_private_network.net.name}"
  create_network     = false
  name               = "${var.network_name}"
  attach_vrack       = "${var.attach_vrack}"
  cidr               = "10.0.0.0/16"
  region             = "SBG3"
  public_subnets     = ["10.0.10.0/24"]
  private_subnets    = ["10.0.11.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true

  metadata = {
    Terraform   = "true"
    Environment = "prod"
  }

  providers = {
    "openstack" = "openstack.SBG3"
  }
}

module "network_DE1" {
  #  source  = "ovh/publiccloud-network/ovh"
  #  version = ">= 0.0.10"
  source = "../.."

  project_id         = "${var.project_id}"
  create_network     = false
  network_name       = "${ovh_publiccloud_private_network.net.name}"
  name               = "${var.network_name}"
  attach_vrack       = "${var.attach_vrack}"
  cidr               = "10.0.0.0/16"
  region             = "DE1"
  public_subnets     = ["10.0.20.0/24"]
  private_subnets    = ["10.0.21.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true

  metadata = {
    Terraform   = "true"
    Environment = "prod"
  }

  providers = {
    "openstack" = "openstack.DE1"
  }
}
