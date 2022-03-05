resource "docker_image" "nodered_image" {
  //name = "nodered/node-red:latest"
  name = var.image_in // module側から参照する、ルート側で定義したvariable
}