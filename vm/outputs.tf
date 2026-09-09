output "instance_external_ip" {
  value = yandex_compute_instance.vm[*].network_interface[0].nat_ip_address
}

output "instance_internal_ip" {
  value = yandex_compute_instance.vm[*].network_interface[0].ip_address
}

output "instance_fqdn" {
  value = yandex_compute_instance.vm[*].fqdn
}

