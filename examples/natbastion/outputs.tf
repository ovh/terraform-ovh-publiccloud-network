output "helper" {
  description = "human friendly helper"
  value = <<DESC
The nat gateway has been setup to allow ssh traffic from 0.0.0.0/0

You may want to configure your ‘~/.ssh/config‘ as follows:
---
$ cat >> ~/.ssh/config <<EOF
Host ${openstack_compute_instance_v2.my_private_instance.name}
  User centos
  Hostname ${openstack_compute_instance_v2.my_private_instance.access_ip_v4}
  ProxyCommand ssh core@${module.network.bastion_public_ip} ncat %h %p
EOF
---

and then ssh into your private boxes by typing:
---
$ ssh ${openstack_compute_instance_v2.my_private_instance.name}
---
DESC
}
