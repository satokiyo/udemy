output "ip-address" {
  #value = join(":", flatten([docker_container.nodered_container[*].ip_address,  docker_container.nodered_container[*].ports[0].external]))
  value = [for i in docker_container.nodered_container[*]: join(":", [i.ip_address], i.ports[*]["external"])]
  description = "The IP address of the container"
//  sensitive = true // sensitive = trueにすると出力を秘匿してくれる
}

output "container-name" {
  value = docker_container.nodered_container.name
  description = "The name of the container"
}