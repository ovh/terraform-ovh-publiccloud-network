Simple Openstack Network with NAT gateway as bastion Host
==========

Configuration in this directory creates set of openstack resources which may be sufficient for development environment.

There's 1 private subnet created in addition to single NAT Gateway.
Hosts within the private subnet can be reached through the NAT gateway which acts as a bastion host.

Pre-Requisites
===

This example assumes you already have attached your openstack project to your OVH VRack.

Usage
=====

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan -var project_id=... -var vrack_id=...
$ terraform apply -var project_id=... -var vrack_id=...
```

Note that this example may create resources which can cost money (Openstack Instance, for example). Run `terraform destroy` when you don't need these resources.
