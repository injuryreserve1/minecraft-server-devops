terraform {
    required_providers {
        docker = {
            source = "kreuzwerker/docker"
            version = "~> 4.2.0"
        }
    }

    backend "local" {
        path = "/home/comp/terraform/minecraft_project/state/terraform.tfstate"
    }
}

provider "docker" {}
