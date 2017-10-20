Simple Openstack Network with Bastion Host
==========

Configuration in this directory creates set of openstack resources which may be sufficient for development environment.

There's 1 private subnet created in addition to single NAT Gateway.
Hosts within the private subnet can be reached through the bastion host.

NOTE: You may want to have a look at the [NAT as a bastion](../natbastion/README.md "NAT as a bastion example") example.

Usage
=====

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan -var project_id=... -var vrack_id=...
$ terraform apply -var project_id=... -var vrack_id=...
```

Note that this example may create resources which can cost money (Openstack Instance, for example). Run `terraform destroy` when you don't need these resources.
