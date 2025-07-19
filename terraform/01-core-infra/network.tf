resource "yandex_vpc_network" "netology-vpc" {
  name = "netology-network"
}

resource "yandex_vpc_subnet" "subnet-a" {
  name           = "subnet-a"
  zone           = var.zone_a
  network_id     = yandex_vpc_network.netology-vpc.id
  v4_cidr_blocks = ["10.10.0.0/24"]
}

resource "yandex_vpc_subnet" "subnet-b" {
  name           = "subnet-b"
  zone           = var.zone_b
  network_id     = yandex_vpc_network.netology-vpc.id
  v4_cidr_blocks = ["10.20.0.0/24"]
}