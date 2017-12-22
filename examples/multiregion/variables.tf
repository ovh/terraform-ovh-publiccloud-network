variable "vrack_id" {
  description = "The id of the vrack"
}

variable "project_id" {
  description = "The id of the openstack project"
}

variable "network_name" {
  description = "The name of the network"
  default     = "mymultiregionnetwork"
}

variable "attach_vrack" {
  description = "Determines if the vrack shall be attached to public cloud project"
  default     = false
}
