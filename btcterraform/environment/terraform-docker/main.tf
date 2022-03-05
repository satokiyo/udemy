resource "null_resource" "dockervol" {
  provisioner "local-exec" {
    command = "mkdir noderedvol/ || true && sudo chown -R 1000:1000 noderedvol/"
  }
}

//resource "docker_image" "nodered_image" {
//  //name = "nodered/node-red:latest"
//  //name = lookup(var.image, terraform.workspace) // type=mapと、env変数を使って、開発と本番環境でイメージを分ける
//  name = var.image[terraform.workspace] // type=mapと、env変数を使って、開発と本番環境でイメージを分ける
//}

// moduleで参照
module "image" {
  source = "./image"
  image_in = var.image[terraform.workspace]
}

resource "random_string" "random" {
  #count = 2
  //count = var.container_count
  count = local.container_count
  length = 4
  special = false
  upper = false
}

module "container" {
  source = "./container"
  // terraform graph で可視化するとわかるが、docker containerのグラフは
  // dockervolに依存しいない！そのため、コンテナ
  // 作成時にvolumeがmkdirされていないと、上手くコンテナが出来ない。
  // そこでdepends_onを書くことで、依存関係を強制してしまう
  depends_on = [null_resource.dockervol]
  #count = 2
  //count = var.container_count
  count = local.container_count
  name_in = join("-", ["nodered", terraform.workspace, random_string.random[count.index].result])
  //image = docker_image.nodered_image.latest
  image_in = module.image.image_out
  int_port_in = var.int_port // noderedのインターナルポートは1880
  ext_port_in = var.ext_port[terraform.workspace][count.index] // lookupなしで
  //external = lookup(var.ext_port, terraform.workspace)[count.index] // エクスターナルポートは自由
  container_path_in = "/data"
  host_path_in = "${path.cwd}/noderedvol"
  //host_path = "/home/ubuntu/environment/terraform-docker/noderedvol"
}

#resource "docker_container" "nodered_container2" {
#  name="nodered-fz8d"
#  image = docker_image.nodered_image.latest
#}
