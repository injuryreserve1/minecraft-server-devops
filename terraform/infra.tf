# общая сеть для контейнеров
resource "docker_network" "mc_net" {
  name = "minecraft-network"
}

# тома для хранения данных
resource "docker_volume" "mc_data" { name = "mc_server_data" }
resource "docker_volume" "mc_backups_store" { name = "mc_server_backups" }
resource "docker_volume" "prometheus_data" { name = "prometheus_data" }
resource "docker_volume" "grafana_data" { name = "grafana_data" }
