{"filter":false,"title":"providers.tf","tooltip":"/terraform-docker/providers.tf","undoManager":{"mark":0,"position":0,"stack":[[{"start":{"row":0,"column":0},"end":{"row":10,"column":0},"action":"insert","lines":["terraform {","  required_providers {","    docker = {","      source  = \"kreuzwerker/docker\"","      version = \"~>2.15.0\" // right most number が一番最新バージョンに自動インクリメントされる","    }","  }","}","","provider \"docker\" {} // local hostの場合は{}内は空でいい",""],"id":1}]]},"ace":{"folds":[],"scrolltop":0,"scrollleft":0,"selection":{"start":{"row":0,"column":0},"end":{"row":0,"column":0},"isBackwards":false},"options":{"guessTabSize":true,"useWrapMode":false,"wrapToView":true},"firstLineState":0},"timestamp":1640873817645,"hash":"86383b9be928c9a27a3e32820bbfb04f0e18adbd"}