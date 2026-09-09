variable "env_name" {
  type    = string
  default = "develop"
}

variable "instance_name" {
  type = string
}

variable "instance_count" {
  type    = number
  default = 1
}

variable "subnet_id" {
  type = string
}

variable "public_ip" {
  type    = bool
  default = false
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "metadata" {
  type    = map(any)
  default = {}
}

variable "security_group_ids" {
  type    = list(string)
  default = []
}

variable "image_id" {
  type        = string
  description = "ID образа для загрузочного диска"
  default     = ""
}

