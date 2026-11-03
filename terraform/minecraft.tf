# образ и контейнер сервера
resource "docker_image" "minecraft" {
  name         = "itzg/minecraft-server:${var.mc_version}"
  keep_locally = true
}

resource "docker_container" "minecraft_server" {
  image   = docker_image.minecraft.image_id
  name    = "mc-devops-project"
  restart = "unless-stopped"
  dns     = ["8.8.8.8", "1.1.1.1"]

  env = [
    "EULA=TRUE",
    "TYPE=PAPER",
    "ONLINE_MODE=FALSE"
  ]

  ports {
    internal = 25565
    external = 25565
  }

  networks_advanced { name = docker_network.mc_net.name }

  volumes {
    volume_name    = docker_volume.mc_data.name
    container_path = "/data"
  }
}

# образ и контейнер бэкапов
resource "docker_image" "mc_backup" {
  name          = "itzg/mc-backup:latest"
  keep_locally = true
}

resource "docker_container" "mc_backup" {
  name    = "mc-backup"
  image   = docker_image.mc_backup.image_id
  restart = "unless-stopped"

  env = [
    "RCON_HOST=mc-devops-project",
    "BACKUP_INTERVAL=6h",
    "PRUNE_BACKUPS_DAYS=7"
  ]

  volumes {
    volume_name    = docker_volume.mc_data.name
    container_path = "/data"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.mc_backups_store.name
    container_path = "/backups"
  }

  networks_advanced {
    name = docker_network.mc_net.name
  }

  depends_on = [docker_container.minecraft_server]
}
