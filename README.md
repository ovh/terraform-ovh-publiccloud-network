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

  name = "my-network"
  cidr = "10.0.0.0/16"

  network_id = "XXX"

  region          = "GRA3"
  public_subnets  = ["10.0.0.0/24"]
  private_subnets = ["10.0.1.0/24"]

  enable_nat_gateway = true

  metadata = {
    Terraform   = "true"
    Environment = "dev"
  }
}
```

## Examples

* [Simple Network](https://github.com/terraform-ovh-modules/terraform-ovh-publiccloud-network/tree/master/examples/simple)
* [Multi Region Network](https://github.com/terraform-ovh-modules/terraform-ovh-publiccloud-network/tree/master/examples/multiregion)

## How do I contribute to this Module?

Contributions are very welcome! Check out the [Contribution Guidelines](https://github.com/terraform-ovh-modules/terraform-ovh-publiccloud-network/tree/master/CONTRIBUTING.md) for instructions.

## Authors

Module managed by [Yann Degat](https://github.com/yanndegat).

## License

Apache 2 Licensed. See LICENSE for full details.
