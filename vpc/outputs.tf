output "vpc_id" {
  value       = yandex_vpc_network.default.id
  description = "ID созданной сети VPC"
}

output "subnet_id" {
  value       = yandex_vpc_subnet.default.id
  description = "ID созданной подсети VPC"
}
