
output "IP-Address" {
  //value = flatten(module.container[*].ip-address)
  value = flatten(module.container[*].ip-address)
  description = "The IP address of the container"
  //sensitive = true // sensitive = trueにすると出力を秘匿してくれる
}

output "container-name" {
  value = module.container[*].container-name
  description = "The name of the container"
}

##output "IP-Address2" {
##  value = join(":", [docker_container.nodered_container[1].ip_address,  docker_container.nodered_container[1].ports[0].external])
##  description = "The IP address of the container"
##}
