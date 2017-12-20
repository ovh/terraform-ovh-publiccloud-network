provider "ovh" {
  endpoint = "ovh-eu"
}

module "network" {
  source = "ovh/publiccloud-network/ovh"
  version = ">= 0.0.8"

  project_id = "${var.project_id}"
  vrack_id   = "${var.vrack_id}"

  attach_vrack = "${var.attach_vrack}"
  name         = "mynetwork"
  cidr         = "10.0.0.0/16"

  region          = "${var.region}"
  public_subnets  = ["10.0.0.0/24"]
  private_subnets = ["10.0.1.0/24"]

  enable_nat_gateway = true
  nat_as_bastion = true
  ssh_public_keys = ["${file("~/.ssh/id_rsa.pub")}"]

  metadata = {
    Terraform   = "true"
    Environment = "Dev"
  }
}
