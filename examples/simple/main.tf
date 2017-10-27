provider "ovh" {
  endpoint = "ovh-eu"
}

module "network" {
  source = "../.."

  project_id = "${var.project_id}"
  vrack_id   = "${var.vrack_id}"

  name = "mynetwork"
  cidr = "10.0.0.0/16"

  region          = "${var.region}"
  public_subnets  = ["10.0.0.0/24"]
  private_subnets = ["10.0.1.0/24"]

  enable_nat_gateway = true

  metadata = {
    Terraform   = "true"
    Environment = "Dev"
  }
}
