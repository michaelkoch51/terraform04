output "out" {
  value       = concat(module.marketing_vm.fqdn, module.analytics_vm.fqdn)
  description = "Список FQDN всех созданных виртуальных машин"
}

output "vms_passwords" {
  value       = { for k, v in random_password.input_vms : k => nonsensitive(v.result) }
  description = "Сгенерированные пароли для ВМ"
}

