terraform {
    required_providers {
        docker = {
            source = "kreuzwerker/docker"
            version = "~> 4.2.0"
        }
    }
}

provider "docker" {}

# общая сеть чтобы контейнеры общались
resource "docker_network" "mc_net" {
    name = "minecraft-network"
}

# 4 тома для данных
resource "docker_volume" "mc_data" {
    name = "mc_server_data"
}
resource "docker_volume" "mc_backups_store" {
    name = "mc_server_backups"
}
resource "docker_volume" "prometheus_data" {
    name = "prometheus_data"
}
resource "docker_volume" "grafana_data" {
    name = "grafana_data"
}

# образ майна
resource "docker_image" "minecraft" {
    name = "itzg/minecraft-server:latest"
    keep_locally = true
}

# образ сервака майна
resource "docker_container" "minecraft_server" {
    image = docker_image.minecraft.image_id
    name = "mc-devops-project"

    restart = "unless-stopped"

    dns = ["8.8.8.8", "1.1.1.1"]

    env = [
        "EULA=TRUE",
        "TYPE=PAPER",
        "ONLINE_MODE=FALSE",
        "PROMETHEUS_HOST=0.0.0.0",
        "PROMETHEUS_PORT=9225"
    ]

    ports {
        internal = 25565
        external = 25565
    }

    networks_advanced {
        name = docker_network.mc_net.name
    }

    volumes {
        volume_name = docker_volume.mc_data.name
        container_path = "/data"
    }

    volumes {
        host_path      = "/home/comp/terraform/minecraft_project/minecraft-prometheus-exporter-3.1.2.jar"
        container_path = "/data/plugins/minecraft-prometheus-exporter-3.1.2.jar"
        read_only      = true
    }

    upload {
        file           = "/data/plugins/PrometheusExporter/config.yml"
        content_base64 = base64encode(<<-EOF
# Конфиг плагина мониторинга
host: 0.0.0.0
port: 9940
enable_metrics:
  chunks: true
  objects: true
  players: true
  jvm: true
EOF
        )
    }

}

# образ бекапа
resource "docker_image" "mc_backup" {
    name         = "itzg/mc-backup:latest"
    keep_locally = true
}

# контейнер бэкапа
resource "docker_container" "mc_backup" {
    name = "mc-backup"
    image = docker_image.mc_backup.image_id

    env = [
        "RCON_HOST=mc-devops-project",
        "BACKUP_INTERVAL=6h",
        "PRUNE_BACKUPS_DAYS=7"
    ]

    volumes {
        volume_name = docker_volume.mc_data.name
        container_path = "/data"
        read_only = true
    }

    volumes {
        volume_name = docker_volume.mc_backups_store.name
        container_path = "/backups"
    }

    networks_advanced {
        name = docker_network.mc_net.name
    }
}

# прометеус 
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

    upload {
        file           = "/etc/prometheus/prometheus.yml"
        content_base64 = base64encode(<<-EOF
global:
  scrape_interval: 5s
scrape_configs:
  - job_name: 'minecraft'
    static_configs:
      - targets: ['mc-devops-project:9940']
EOF
        )
    }

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
}

## графана 
resource "docker_image" "grafana" {
    name         = "grafana/grafana-oss:latest"
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
}