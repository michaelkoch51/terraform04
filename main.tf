# 1. Модуль сети из Задания 2
module "vpc_dev" {
  source   = "./vpc"
  env_name = "develop"
  zone     = "ru-central1-a"
  cidr     = "10.0.1.0/24"
}

# 2. Модуль для ВМ маркетинга из Задания 1
module "marketing_vm" {
  source = "git::https://github.com/michaelkoch51/terraform04.git//vm?ref=main"
  env_name       = "marketing"
  network_id     = module.vpc_dev.vpc_id
  subnet_zones   = ["ru-central1-a"]
  subnet_ids     = [module.vpc_dev.subnet_id]
  instance_name  = "marketing"
  instance_count = 1
  public_ip      = true
  labels = { project = "marketing" }
  metadata = {
    user-data          = templatefile("${path.module}/templates/cloud-init.tftpl", { ssh_key = var.public_key })
    serial-port-enable = 1
  }
}

# 3. Модуль для ВМ аналитики из Задания 1
module "analytics_vm" {
  source = "git::https://github.com/michaelkoch51/terraform04.git//vm?ref=main"
  env_name       = "analytics"
  network_id     = module.vpc_dev.vpc_id
  subnet_zones   = ["ru-central1-a"]
  subnet_ids     = [module.vpc_dev.subnet_id]
  instance_name  = "analytics"
  instance_count = 1
  public_ip      = true
  labels = { project = "analytics" }
  metadata = {
    user-data          = templatefile("${path.module}/templates/cloud-init.tftpl", { ssh_key = var.public_key })
    serial-port-enable = 1
  }
}

# 4. Generator
resource "random_password" "input_vms" {
  for_each = toset(["marketing", "analytics"])
  length   = 16
}
