variable "name" {
  description = "Name to be used on all the resources as identifier"
}

variable "vrack_id" {
  description = "The id of the vrack. This is required if network_id is not specified."
  default     = ""
}

variable "project_id" {
  description = "The id of the openstack project. This is required if network_id is not specified."
  default     = ""
}

variable "network_id" {
  description = <<DESC
The network id used to create the subnets. If not specified, an openstack network
 will be created through the openstack API.

NOTE: As of today, the network has to pre-created outside this module
if you want to do cross regions networking with the vrack.
See "multiregion" example.
DESC

  default = ""
}

variable "cidr" {
  description = "The CIDR block of the Network. (e.g. 10.0.0.0/16)"
}

variable "public_subnets" {
  type = "list"

  description = <<DESC
Public subnets are meant for every instances that can be
reached through the internet (e.g. NATs, LBs, Bastion hosts, ...).
Note: The NAT Gateways will be fixed to the 2nd ip of these subnets
      and the allocation pools will start at the 3rd ip
DESC

  default = []
}

variable "private_subnets" {
  type        = "list"
  description = "A list of private subnets inside the VPC"
  default     = []
}

variable "nat_ssh_public_keys" {
  type = "list"

  description = <<DESC
The ssh public keys which could be used for nat instances.
This can be usefull if one would like to use the nat instances as
ssh proxies.
DESC

  default = []
}

variable "nat_instance_flavor_names" {
  type = "map"

  description = "A map of flavor names per openstack region that will be used for NAT Gateways."

  default = {
    GRA1 = "s1-2"
    SBG3 = "s1-2"
    GRA3 = "s1-2"
    SBG3 = "s1-2"
    BHS3 = "s1-2"
    WAW1 = "s1-2"
    DE1  = "s1-2"
  }
}

variable "enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways for each of your private subnets"
  default     = false
}

variable "single_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways for each of your private subnets"
  default     = false
}

variable "region" {
  description = "The id of the openstack region"
}

variable "ovh_pub_nets" {
  type = "map"

  description = "A map of ovh public openstack network names."

  default = {
    GRA3 = "Ext-Net"
    SBG3 = "Ext-Net"
    BHS3 = "Ext-Net"
    GRA1 = "Ext-Net"
    SBG1 = "Ext-Net"
    BHS1 = "Ext-Net"
    DE1  = "Ext-Net"
    WAW1 = "Ext-Net"
  }
}

variable "dns_nameservers" {
  type        = "list"
  description = "The list of dns servers to be pushed by dhcp"
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "metadata" {
  description = "A map of metadata to add to all resources supporting it."
  default     = {}
}
