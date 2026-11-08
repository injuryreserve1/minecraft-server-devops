# Prometheus
resource "docker_image" "prometheus" {
  name         = "prom/prometheus:latest"
  keep_locally = true
}

resource "docker_container" "prometheus" {
  name    = "prometheus"
  image   = docker_image.prometheus.image_id
  restart = "unless-stopped"
  
  command = [
    "--config.file=/etc/prometheus/prometheus.yml",
    "--storage.tsdb.path=/prometheus"
  ]

  ports {
    internal = 9090
    external = 9090
  }

  networks_advanced {
    name = docker_network.mc_net.name
  }

  volumes {
    volume_name    = docker_volume.prometheus_data.name
    container_path = "/prometheus"
  }

  volumes {
    host_path      = "${path.cwd}/../templates/prometheus.yml"
    container_path = "/etc/prometheus/prometheus.yml"
  }


  depends_on = [docker_container.minecraft_server]
}

# Grafana
resource "docker_image" "grafana" {
  name          = "grafana/grafana-oss:latest"
  keep_locally = true
}

resource "docker_container" "grafana" {
  name    = "grafana"
  image   = docker_image.grafana.image_id
  restart = "unless-stopped"

  ports {
    internal = 3000
    external = 3000
  }

  networks_advanced {
    name = docker_network.mc_net.name
  }

  volumes {
    volume_name    = docker_volume.grafana_data.name
    container_path = "/var/lib/grafana"
  }

  volumes {
    host_path      = "${path.cwd}/../templates/grafana_datasource.yml"
    container_path = "/etc/grafana/provisioning/datasources/datasource.yaml"
  }

  depends_on = [docker_container.prometheus]
}

# импортер
resource "docker_image" "mc_exporter" {
  name         = "itzg/mc-monitor:latest"
  keep_locally = true
}

resource "docker_container" "mc_exporter" {
  name    = "mc-exporter"
  image   = docker_image.mc_exporter.image_id
  restart = "unless-stopped"

  command = [
    "export-for-prometheus",
    "-servers=mc-devops-project:25565"
  ]

  ports {
    internal = 8080
    external = 9851
  }

  networks_advanced { name = docker_network.mc_net.name }
  depends_on        = [docker_container.minecraft_server]
}