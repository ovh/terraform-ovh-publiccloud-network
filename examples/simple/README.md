Simple Openstack Network
==========

Configuration in this directory creates set of openstack resources which may be sufficient for development environment.

There's 1 private subnet created in addition to single NAT Gateway.

NOTE: Once a network has been created, you cannot set a VLAN id (or segmentation id).
Meaning you won't be able to do cross region networking using this setup. Instead you should
have a look at the [multiregion example]((https://github.com/ovh/terraform-ovh-publiccloud-network/tree/master/examples/multiregion/README.md "multiregion example").

Usage
=====

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan -var project_id=... -var vrack_id=...
$ terraform apply -var project_id=... -var vrack_id=...
```

Note that this example may create resources which can cost money (Openstack Instance, for example). Run `terraform destroy` when you don't need these resources.
