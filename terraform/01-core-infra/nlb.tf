resource "yandex_lb_target_group" "shared_target_group" {
  name = "shared-target-group"

  dynamic "target" {
    for_each = yandex_compute_instance.k8s-worker
    content {
      subnet_id = target.value.network_interface[0].subnet_id
      address   = target.value.network_interface[0].ip_address
    }
  }
}

resource "yandex_lb_network_load_balancer" "nlb" {
  name = "nlb-for-grafana-and-app"

  listener {
    name        = "grafana-listener"
    port        = 80        # Внешний порт (графана)
    target_port = 32000     # NodePort для графаны
    protocol    = "tcp"
  }

  listener {
    name        = "test-app-listener"
    port        = 8080      # Внешний порт (тестовая страница)
    target_port = 32001     # NodePort для nginx
    protocol    = "tcp"
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.shared_target_group.id

    healthcheck {
      name = "tcp-hc"
      tcp_options {
        port = 32000  # Один из рабочих портов (например, Grafana)
      }
    }
  }

  depends_on = [yandex_lb_target_group.shared_target_group]
}
