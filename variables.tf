variable "token" { 
  type = string 
}

variable "cloud_id" { 
  type = string 
}

variable "folder_id" { 
  type = string 
}

variable "default_zone" { 
  type    = string
  default = "ru-central1-a" 
}

variable "public_key" {
  type    = string
  default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHhnPBOth6dhI4Bdo1EyHMtaJP0w8jwnGkuIhxm9uieF misha.kochnev@gmail.com"
}

