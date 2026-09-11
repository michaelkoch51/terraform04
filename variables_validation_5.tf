# ============================================================
# Задание 5*: Переменные со сложной валидацией
# ============================================================

# Строка без заглавных букв
variable "lowercase_string" {
  type        = string
  description = "любая строка"
  default     = "hello world"

  validation {
    condition     = var.lowercase_string == lower(var.lowercase_string)
    error_message = "Строка не должна содержать заглавных букв."
  }
}

# Object: только один MacLeod
variable "in_the_end_there_can_be_only_one" {
  description = "Who is better Connor or Duncan?"
  type = object({
    Dunkan = optional(bool)
    Connor = optional(bool)
  })

default = {
  Dunkan = true
  Connor = false
}

  validation {
    condition = (
      var.in_the_end_there_can_be_only_one.Dunkan !=
      var.in_the_end_there_can_be_only_one.Connor
    )
    error_message = "There can be only one MacLeod"
  }
}
