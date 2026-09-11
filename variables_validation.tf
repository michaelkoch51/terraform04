# ============================================================
# Задание 4: Переменные с валидацией
# ============================================================

# Одиночный IP-адрес
variable "ip_address" {
  type        = string
  description = "ip-адрес"
  default     = "192.168.0.1"

  validation {
    condition     = can(cidrhost("${var.ip_address}/32", 0))
    error_message = "Значение должно быть корректным IP-адресом (например, 192.168.0.1)."
  }
}

# Список IP-адресов
variable "ip_list" {
  type        = list(string)
  description = "список ip-адресов"
  default     = ["192.168.0.1", "1.1.1.1", "127.0.0.1"]

  validation {
    condition = alltrue([
      for ip in var.ip_list : can(cidrhost("${ip}/32", 0))
    ])
    error_message = "Все элементы списка должны быть корректными IP-адресами."
  }
}
