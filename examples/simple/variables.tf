variable "vrack_id" {
  description = "The id of the vrack"
  default     = ""
}

variable "project_id" {
  description = "The id of the openstack project"
}

variable "region" {
  description = "The id of the openstack region"
  default = "SBG3"
}

variable "attach_vrack" {
  description = "If set, attach openstack to vrack"
  default     = false
}
