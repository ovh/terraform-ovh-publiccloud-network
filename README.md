# OVH PublicCloud Network Terraform module

This repo contains a [Terraform Module](https://www.terraform.io/docs/modules/index.html "Terraform Module") for how to deploy network resources on OVH PublicCloud.

These types of resources are supported:

* [VRack Public Cloud attachment](https://www.terraform.io/docs/providers/ovh/r/vrack_publiccloud_attachment.html)
* [Security Group](https://www.terraform.io/docs/providers/openstack/r/networking_secgroup_v2.html)
* [Network](https://www.terraform.io/docs/providers/openstack/r/networking_network_v2.html)
* [Subnet](https://www.terraform.io/docs/providers/openstack/r/networking_subnet_v2.html)
* [Port](https://www.terraform.io/docs/providers/openstack/r/networking_port_v2.html)
* [Instance](https://www.terraform.io/docs/providers/openstack/r/compute_instance_v2.html)

# Usage

```hcl
module "network" {
  source = "terraform-ovh-modules/publiccloud_network/ovh"

  project_id      = "XXX"
  vrack_id        = "YYY"
  name            = "my-network"
  region          = "GRA3"
  cidr            = "10.0.0.0/16"
  public_subnets  = ["10.0.0.0/24"]
  private_subnets = ["10.0.1.0/24"]

  enable_nat_gateway  = true
  enable_bastion_host = true

  metadata = {
    Terraform   = "true"
    Environment = "dev"
  }
}
```

## Examples

* [Simple Network](./examples/simple/README.md)
* [Multi Region Network](./examples/multiregion/README.md)
* [Simple Network with bastion host](./examples/bastion/README.md)
* [Simple Network with NAT Gateway as a bastion host](./examples/natbastion/README.md)

## How do I contribute to this Module?

Contributions are very welcome! Check out the [Contribution Guidelines](CONTRIBUTING.md) for instructions.

## Authors

Module managed by [Yann Degat](https://github.com/yanndegat).

## License

Apache 2 Licensed. See LICENSE for full details.
