resource "yandex_compute_instance" "jenkins" {
  name        = "docker-jenkins"
  zone        = "ru-central1-a"
  platform_id = "standard-v2"

  # hostname    = "jenkins"
  
  resources {
    cores         = 4
    memory        = 4
    core_fraction = 5
  }

  boot_disk {
    initialize_params {
      image_id = "fd8m2ak64lipvicd94sf"
      type = "network-hdd"
      size = 25
    }
  }

  scheduling_policy {
    preemptible = var.preemptible
  }

  network_interface {
    subnet_id      = yandex_vpc_subnet.subnet-a.id
    nat            = true
  }

  metadata = var.metadata

}