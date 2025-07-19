resource "yandex_compute_instance" "k8s-master" {
  name        = "k8s-master"
  zone        = "ru-central1-a"
  platform_id = "standard-v2"
  
  resources {
    cores  = 2
    memory = 4
    core_fraction = 5
  }

  boot_disk {
    initialize_params {
      image_id = "fd8m2ak64lipvicd94sf"
      size     = 20
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

resource "yandex_compute_instance" "k8s-worker" {
  count       = 2
  name        = "k8s-worker-${count.index + 1}"
  zone        = "ru-central1-${element(["a", "b"], count.index)}"
  platform_id = "standard-v2"
  resources {
    cores  = 2
    memory = 2
    core_fraction = 5
  }

  scheduling_policy {
    preemptible = var.preemptible
  }
  
  boot_disk {
    initialize_params {
      image_id = "fd8m2ak64lipvicd94sf"
      size     = 20
    }
  }

  network_interface {
    subnet_id      = element([yandex_vpc_subnet.subnet-a.id, yandex_vpc_subnet.subnet-b.id], count.index)
    nat            = true
  }

  metadata = var.metadata
}