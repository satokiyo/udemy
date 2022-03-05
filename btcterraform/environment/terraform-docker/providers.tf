terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~>2.15.0" // right most number が一番最新バージョンに自動インクリメントされる
    }
  }
}

provider "docker" {} // local hostの場合は{}内は空でいい
