# vm/main.tf
resource "yandex_compute_instance" "vm" {
  count       = var.instance_count
  name        = "${var.env_name}-${var.instance_name}-${count.index + 1}"
  platform_id = "standard-v3"

  resources {
    cores  = 2
  memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd80bm0rh4rbebm5b1rn" # Ubuntu 22.04
    }
  }

  scheduling_policy {
    preemptible = true
  }

  network_interface {
    subnet_id          = var.subnet_id
    nat                = var.public_ip
    security_group_ids = var.security_group_ids
  }

  metadata = var.metadata

  labels = var.labels
}

