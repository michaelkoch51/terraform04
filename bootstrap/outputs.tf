output "bucket_name" {
  value       = yandex_storage_bucket.tfstate.bucket
  description = "S3 bucket name for Terraform state"
}

output "access_key" {
  value       = yandex_iam_service_account_static_access_key.tfstate_sa_key.access_key
  description = "Static access key ID"
  sensitive   = true
}

output "secret_key" {
  value       = yandex_iam_service_account_static_access_key.tfstate_sa_key.secret_key
  description = "Static secret key"
  sensitive   = true
}

output "backend_config_example" {
  value = <<-EOT
    terraform {
      backend "s3" {
        bucket = "${yandex_storage_bucket.tfstate.bucket}"
        key    = "terraform.tfstate"
        region = "ru-central1"

        use_lockfile = true

        endpoints = {
          s3 = "https://storage.yandexcloud.net"
        }

        skip_region_validation      = true
        skip_credentials_validation = true
        skip_requesting_account_id  = true
        skip_s3_checksum            = true
      }
    }
  EOT
  description = "Example backend configuration"
}
