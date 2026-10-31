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

# 2 тома для данных
resource "docker_volume" "mc_data" {
    name = "mc_server_data"
}
resource "docker_volume" "mc_backups_store" {
    name = "mc_server_backups"
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

    env = [
        "EULA=TRUE",
        "TYPE=VANILLA"
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