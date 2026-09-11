terraform {
   required_version = ">= 1.12.0, < 2.0.0" 
   required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.120"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Remote state с встроенными блокировками (Terraform >= 1.6)
  # Не требует отдельной базы данных для lock-файла!
  backend "s3" {
    bucket = "michael-terraform-state-2026"
    key    = "terraform04/terraform.tfstate"
    region = "ru-central1"

    # Встроенный механизм блокировок
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

provider "yandex" {
  token     = var.token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.default_zone
}
