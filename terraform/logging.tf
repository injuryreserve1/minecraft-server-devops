# Образ и контейнер Loki (база данных для логов)
resource "docker_image" "loki" {
  name         = "grafana/loki:3.0.0"
  keep_locally = true
}

resource "docker_container" "loki" {
  name    = "loki"
  image   = docker_image.loki.image_id
  restart = "unless-stopped"
  
  ports {
    internal = 3100
    external = 3100
  }

  networks_advanced { name = docker_network.mc_net.name }
}

# Образ и контейнер Promtail (агент-сборщик логов)
resource "docker_image" "promtail" {
  name         = "grafana/promtail:3.0.0"
  keep_locally = true
}

resource "docker_container" "promtail" {
  name    = "promtail"
  image   = docker_image.promtail.image_id
  restart = "unless-stopped"

  command = ["-config.file=/etc/promtail/config.yml"]

  volumes {
    host_path      = "${path.cwd}/../templates/promtail.yml"
    container_path = "/etc/promtail/config.yml"
  }

  volumes {
    host_path      = "/var/lib/docker/containers"
    container_path = "/var/log/pods"
    read_only      = true
  }

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }

  networks_advanced { name = docker_network.mc_net.name }
  depends_on        = [docker_container.loki]
}
