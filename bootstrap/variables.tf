variable "token" {
  type        = string
  description = "IAM token for Yandex Cloud"
  sensitive   = true
}

variable "cloud_id" {
  type        = string
  description = "Yandex Cloud ID"
}

variable "folder_id" {
  type        = string
  description = "Yandex Cloud folder ID"
}

variable "bucket_name" {
  type        = string
  description = "S3 bucket name for Terraform state"
  default     = "terraform04-bootstrap-demo"
}

variable "sa_name" {
  type        = string
  description = "Service account name for state"
  default     = "terraform04-bootstrap-sa"
}
