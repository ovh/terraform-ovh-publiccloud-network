Openstack Network with Bastion Host
==========

Configuration in this directory creates set of openstack resources to boot a multi subnets network infrasctucture.

There are 2 private subnets created in addition to 2 public subnets, each with a dedicated NAT Gateway.
Hosts within the private subnets can be reached through the bastion host.

NOTE: You may want to have a look at the [NAT as a bastion]((https://github.com/ovh/terraform-ovh-publiccloud-network/tree/master/examples/natbastion/README.md "NAT as a bastion example") example.

Usage
=====

To run this example you need to execute:

```bash
$ terraform init
$ terraform apply -var project_id=... -var vrack_id=...
```

Note that this example may create resources which can cost money (Openstack Instance, for example). Run `terraform destroy` when you don't need these resources.
