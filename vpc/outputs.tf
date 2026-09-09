output "vpc_id" {
  value       = yandex_vpc_network.network.id
  description = "ID созданной сети VPC"
}

output "subnet_id" {
  value       = yandex_vpc_subnet.subnet.id
  description = "ID созданной подсети VPC"
}
