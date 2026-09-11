provider "yandex" {
  token     = var.token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
}

# S3 bucket для Terraform state с версионированием
resource "yandex_storage_bucket" "tfstate" {
  bucket    = var.bucket_name
  folder_id = var.folder_id    # ← добавить

  versioning {
    enabled = true
  }

  max_size = 1073741824
}

# Сервисный аккаунт для работы с state
resource "yandex_iam_service_account" "tfstate_sa" {
  name        = var.sa_name
  description = "Service account for Terraform remote state"
}

# Права storage.editor на folder
resource "yandex_resourcemanager_folder_iam_member" "tfstate_sa_storage_editor" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.tfstate_sa.id}"
}

# Static access key для SA
resource "yandex_iam_service_account_static_access_key" "tfstate_sa_key" {
  service_account_id = yandex_iam_service_account.tfstate_sa.id
  description        = "Static access key for Terraform state"
}
