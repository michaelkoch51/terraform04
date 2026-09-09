variable "env_name" {
  type        = string
  description = "Имя окружения (develop, marketing и т.д.)"
}

variable "zone" {
  type        = string
  description = "Зона доступности Yandex Cloud"
}

variable "cidr" {
  type        = string
  description = "CIDR блок для подсети"
}

