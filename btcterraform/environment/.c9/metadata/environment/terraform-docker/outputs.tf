{"filter":false,"title":"outputs.tf","tooltip":"/terraform-docker/outputs.tf","undoManager":{"mark":67,"position":67,"stack":[[{"start":{"row":0,"column":0},"end":{"row":16,"column":0},"action":"insert","lines":["","output \"IP-Address\" {","  #value = join(\":\", flatten([docker_container.nodered_container[*].ip_address,  docker_container.nodered_container[*].ports[0].external]))","  value = [for i in docker_container.nodered_container[*]: join(\":\", [i.ip_address], i.ports[*][\"external\"])]","  description = \"The IP address of the container\"","}","","output \"container-name\" {","  value = docker_container.nodered_container[*].name","  description = \"The name of the container\"","}","","#output \"IP-Address2\" {","#  value = join(\":\", [docker_container.nodered_container[1].ip_address,  docker_container.nodered_container[1].ports[0].external])","#  description = \"The IP address of the container\"","#}",""],"id":1}],[{"start":{"row":4,"column":49},"end":{"row":5,"column":0},"action":"insert","lines":["",""],"id":5},{"start":{"row":5,"column":0},"end":{"row":5,"column":2},"action":"insert","lines":["  "]}],[{"start":{"row":5,"column":2},"end":{"row":5,"column":3},"action":"insert","lines":["s"],"id":6},{"start":{"row":5,"column":3},"end":{"row":5,"column":4},"action":"insert","lines":["e"]},{"start":{"row":5,"column":4},"end":{"row":5,"column":5},"action":"insert","lines":["n"]},{"start":{"row":5,"column":5},"end":{"row":5,"column":6},"action":"insert","lines":["s"]},{"start":{"row":5,"column":6},"end":{"row":5,"column":7},"action":"insert","lines":["i"]}],[{"start":{"row":5,"column":2},"end":{"row":5,"column":7},"action":"remove","lines":["sensi"],"id":7},{"start":{"row":5,"column":2},"end":{"row":5,"column":11},"action":"insert","lines":["sensitive"]}],[{"start":{"row":5,"column":11},"end":{"row":5,"column":12},"action":"insert","lines":["="],"id":8},{"start":{"row":5,"column":12},"end":{"row":5,"column":13},"action":"insert","lines":["t"]},{"start":{"row":5,"column":13},"end":{"row":5,"column":14},"action":"insert","lines":["r"]},{"start":{"row":5,"column":14},"end":{"row":5,"column":15},"action":"insert","lines":["u"]},{"start":{"row":5,"column":15},"end":{"row":5,"column":16},"action":"insert","lines":["e"]}],[{"start":{"row":5,"column":11},"end":{"row":5,"column":12},"action":"insert","lines":[" "],"id":9}],[{"start":{"row":5,"column":13},"end":{"row":5,"column":14},"action":"insert","lines":[" "],"id":10}],[{"start":{"row":5,"column":0},"end":{"row":5,"column":1},"action":"insert","lines":["/"],"id":11},{"start":{"row":5,"column":1},"end":{"row":5,"column":2},"action":"insert","lines":["/"]}],[{"start":{"row":5,"column":20},"end":{"row":5,"column":21},"action":"insert","lines":[" "],"id":12},{"start":{"row":5,"column":21},"end":{"row":5,"column":22},"action":"insert","lines":["/"]},{"start":{"row":5,"column":22},"end":{"row":5,"column":23},"action":"insert","lines":["/"]}],[{"start":{"row":5,"column":23},"end":{"row":5,"column":24},"action":"insert","lines":[" "],"id":13},{"start":{"row":5,"column":24},"end":{"row":5,"column":25},"action":"insert","lines":["s"]},{"start":{"row":5,"column":25},"end":{"row":5,"column":26},"action":"insert","lines":["e"]},{"start":{"row":5,"column":26},"end":{"row":5,"column":27},"action":"insert","lines":["n"]}],[{"start":{"row":5,"column":24},"end":{"row":5,"column":27},"action":"remove","lines":["sen"],"id":14},{"start":{"row":5,"column":24},"end":{"row":5,"column":33},"action":"insert","lines":["sensitive"]}],[{"start":{"row":5,"column":33},"end":{"row":5,"column":34},"action":"insert","lines":[" "],"id":15},{"start":{"row":5,"column":34},"end":{"row":5,"column":35},"action":"insert","lines":["="]}],[{"start":{"row":5,"column":35},"end":{"row":5,"column":36},"action":"insert","lines":[" "],"id":16},{"start":{"row":5,"column":36},"end":{"row":5,"column":37},"action":"insert","lines":["t"]},{"start":{"row":5,"column":37},"end":{"row":5,"column":38},"action":"insert","lines":["r"]},{"start":{"row":5,"column":38},"end":{"row":5,"column":39},"action":"insert","lines":["u"]},{"start":{"row":5,"column":39},"end":{"row":5,"column":40},"action":"insert","lines":["e"]}],[{"start":{"row":5,"column":40},"end":{"row":5,"column":44},"action":"insert","lines":["にすると"],"id":17}],[{"start":{"row":5,"column":44},"end":{"row":5,"column":46},"action":"insert","lines":["出力"],"id":18},{"start":{"row":5,"column":46},"end":{"row":5,"column":47},"action":"insert","lines":["を"]}],[{"start":{"row":5,"column":47},"end":{"row":5,"column":49},"action":"insert","lines":["秘匿"],"id":19},{"start":{"row":5,"column":49},"end":{"row":5,"column":54},"action":"insert","lines":["してくれる"]}],[{"start":{"row":16,"column":0},"end":{"row":16,"column":1},"action":"insert","lines":["#"],"id":20},{"start":{"row":15,"column":0},"end":{"row":15,"column":1},"action":"insert","lines":["#"]},{"start":{"row":14,"column":0},"end":{"row":14,"column":1},"action":"insert","lines":["#"]},{"start":{"row":13,"column":0},"end":{"row":13,"column":1},"action":"insert","lines":["#"]},{"start":{"row":12,"column":0},"end":{"row":12,"column":1},"action":"insert","lines":["#"]},{"start":{"row":11,"column":0},"end":{"row":11,"column":1},"action":"insert","lines":["#"]},{"start":{"row":10,"column":0},"end":{"row":10,"column":1},"action":"insert","lines":["#"]},{"start":{"row":9,"column":0},"end":{"row":9,"column":1},"action":"insert","lines":["#"]},{"start":{"row":8,"column":0},"end":{"row":8,"column":1},"action":"insert","lines":["#"]},{"start":{"row":7,"column":0},"end":{"row":7,"column":1},"action":"insert","lines":["#"]},{"start":{"row":6,"column":0},"end":{"row":6,"column":1},"action":"insert","lines":["#"]},{"start":{"row":5,"column":0},"end":{"row":5,"column":1},"action":"insert","lines":["#"]},{"start":{"row":4,"column":0},"end":{"row":4,"column":1},"action":"insert","lines":["#"]},{"start":{"row":3,"column":0},"end":{"row":3,"column":1},"action":"insert","lines":["#"]},{"start":{"row":2,"column":0},"end":{"row":2,"column":1},"action":"insert","lines":["#"]},{"start":{"row":1,"column":0},"end":{"row":1,"column":1},"action":"insert","lines":["#"]},{"start":{"row":0,"column":0},"end":{"row":0,"column":1},"action":"insert","lines":["#"]}],[{"start":{"row":11,"column":0},"end":{"row":11,"column":1},"action":"remove","lines":["#"],"id":21},{"start":{"row":10,"column":0},"end":{"row":10,"column":1},"action":"remove","lines":["#"]},{"start":{"row":9,"column":0},"end":{"row":9,"column":1},"action":"remove","lines":["#"]},{"start":{"row":8,"column":0},"end":{"row":8,"column":1},"action":"remove","lines":["#"]}],[{"start":{"row":9,"column":10},"end":{"row":9,"column":52},"action":"remove","lines":["docker_container.nodered_container[*].name"],"id":22}],[{"start":{"row":9,"column":10},"end":{"row":9,"column":11},"action":"insert","lines":["m"],"id":23},{"start":{"row":9,"column":11},"end":{"row":9,"column":12},"action":"insert","lines":["o"]},{"start":{"row":9,"column":12},"end":{"row":9,"column":13},"action":"insert","lines":["d"]},{"start":{"row":9,"column":13},"end":{"row":9,"column":14},"action":"insert","lines":["u"]},{"start":{"row":9,"column":14},"end":{"row":9,"column":15},"action":"insert","lines":["l"]},{"start":{"row":9,"column":15},"end":{"row":9,"column":16},"action":"insert","lines":["e"]},{"start":{"row":9,"column":16},"end":{"row":9,"column":17},"action":"insert","lines":["."]}],[{"start":{"row":9,"column":17},"end":{"row":9,"column":18},"action":"insert","lines":["c"],"id":24},{"start":{"row":9,"column":18},"end":{"row":9,"column":19},"action":"insert","lines":["o"]},{"start":{"row":9,"column":19},"end":{"row":9,"column":20},"action":"insert","lines":["n"]},{"start":{"row":9,"column":20},"end":{"row":9,"column":21},"action":"insert","lines":["t"]},{"start":{"row":9,"column":21},"end":{"row":9,"column":22},"action":"insert","lines":["a"]},{"start":{"row":9,"column":22},"end":{"row":9,"column":23},"action":"insert","lines":["i"]},{"start":{"row":9,"column":23},"end":{"row":9,"column":24},"action":"insert","lines":["n"]},{"start":{"row":9,"column":24},"end":{"row":9,"column":25},"action":"insert","lines":["e"]},{"start":{"row":9,"column":25},"end":{"row":9,"column":26},"action":"insert","lines":["r"]}],[{"start":{"row":9,"column":26},"end":{"row":9,"column":27},"action":"insert","lines":["."],"id":25},{"start":{"row":9,"column":27},"end":{"row":9,"column":28},"action":"insert","lines":["c"]},{"start":{"row":9,"column":28},"end":{"row":9,"column":29},"action":"insert","lines":["o"]},{"start":{"row":9,"column":29},"end":{"row":9,"column":30},"action":"insert","lines":["n"]},{"start":{"row":9,"column":30},"end":{"row":9,"column":31},"action":"insert","lines":["t"]},{"start":{"row":9,"column":31},"end":{"row":9,"column":32},"action":"insert","lines":["a"]}],[{"start":{"row":9,"column":32},"end":{"row":9,"column":33},"action":"insert","lines":["i"],"id":26},{"start":{"row":9,"column":33},"end":{"row":9,"column":34},"action":"insert","lines":["n"]},{"start":{"row":9,"column":34},"end":{"row":9,"column":35},"action":"insert","lines":["e"]},{"start":{"row":9,"column":35},"end":{"row":9,"column":36},"action":"insert","lines":["r"]},{"start":{"row":9,"column":36},"end":{"row":9,"column":37},"action":"insert","lines":["-"]}],[{"start":{"row":9,"column":37},"end":{"row":9,"column":38},"action":"insert","lines":["n"],"id":27},{"start":{"row":9,"column":38},"end":{"row":9,"column":39},"action":"insert","lines":["a"]},{"start":{"row":9,"column":39},"end":{"row":9,"column":40},"action":"insert","lines":["m"]},{"start":{"row":9,"column":40},"end":{"row":9,"column":41},"action":"insert","lines":["e"]}],[{"start":{"row":9,"column":26},"end":{"row":9,"column":27},"action":"insert","lines":["["],"id":28},{"start":{"row":9,"column":27},"end":{"row":9,"column":28},"action":"insert","lines":["]"]}],[{"start":{"row":9,"column":27},"end":{"row":9,"column":28},"action":"insert","lines":["*"],"id":29}],[{"start":{"row":7,"column":0},"end":{"row":7,"column":1},"action":"remove","lines":["#"],"id":30},{"start":{"row":6,"column":0},"end":{"row":6,"column":1},"action":"remove","lines":["#"]},{"start":{"row":5,"column":0},"end":{"row":5,"column":1},"action":"remove","lines":["#"]},{"start":{"row":4,"column":0},"end":{"row":4,"column":1},"action":"remove","lines":["#"]},{"start":{"row":3,"column":0},"end":{"row":3,"column":1},"action":"remove","lines":["#"]},{"start":{"row":2,"column":0},"end":{"row":2,"column":1},"action":"remove","lines":["#"]},{"start":{"row":1,"column":0},"end":{"row":1,"column":1},"action":"remove","lines":["#"]},{"start":{"row":0,"column":0},"end":{"row":0,"column":1},"action":"remove","lines":["#"]}],[{"start":{"row":2,"column":0},"end":{"row":3,"column":0},"action":"remove","lines":["  #value = join(\":\", flatten([docker_container.nodered_container[*].ip_address,  docker_container.nodered_container[*].ports[0].external]))",""],"id":31}],[{"start":{"row":2,"column":10},"end":{"row":2,"column":109},"action":"remove","lines":["[for i in docker_container.nodered_container[*]: join(\":\", [i.ip_address], i.ports[*][\"external\"])]"],"id":32}],[{"start":{"row":2,"column":10},"end":{"row":2,"column":11},"action":"insert","lines":["m"],"id":33},{"start":{"row":2,"column":11},"end":{"row":2,"column":12},"action":"insert","lines":["o"]}],[{"start":{"row":2,"column":10},"end":{"row":2,"column":12},"action":"remove","lines":["mo"],"id":34},{"start":{"row":2,"column":10},"end":{"row":2,"column":16},"action":"insert","lines":["module"]}],[{"start":{"row":2,"column":16},"end":{"row":2,"column":17},"action":"insert","lines":["."],"id":35},{"start":{"row":2,"column":17},"end":{"row":2,"column":18},"action":"insert","lines":["c"]},{"start":{"row":2,"column":18},"end":{"row":2,"column":19},"action":"insert","lines":["o"]},{"start":{"row":2,"column":19},"end":{"row":2,"column":20},"action":"insert","lines":["n"]}],[{"start":{"row":2,"column":17},"end":{"row":2,"column":20},"action":"remove","lines":["con"],"id":36},{"start":{"row":2,"column":17},"end":{"row":2,"column":26},"action":"insert","lines":["container"]}],[{"start":{"row":2,"column":26},"end":{"row":2,"column":28},"action":"insert","lines":["[]"],"id":37}],[{"start":{"row":2,"column":27},"end":{"row":2,"column":28},"action":"insert","lines":["*"],"id":38}],[{"start":{"row":2,"column":29},"end":{"row":2,"column":30},"action":"insert","lines":["."],"id":39},{"start":{"row":2,"column":30},"end":{"row":2,"column":31},"action":"insert","lines":["c"]}],[{"start":{"row":2,"column":30},"end":{"row":2,"column":31},"action":"remove","lines":["c"],"id":40}],[{"start":{"row":2,"column":30},"end":{"row":2,"column":31},"action":"insert","lines":["i"],"id":41},{"start":{"row":2,"column":31},"end":{"row":2,"column":32},"action":"insert","lines":["p"]}],[{"start":{"row":2,"column":30},"end":{"row":2,"column":32},"action":"remove","lines":["ip"],"id":42},{"start":{"row":2,"column":30},"end":{"row":2,"column":40},"action":"insert","lines":["ip_address"]}],[{"start":{"row":2,"column":32},"end":{"row":2,"column":33},"action":"remove","lines":["_"],"id":44}],[{"start":{"row":2,"column":32},"end":{"row":2,"column":33},"action":"insert","lines":["-"],"id":45}],[{"start":{"row":2,"column":10},"end":{"row":2,"column":11},"action":"insert","lines":["f"],"id":46},{"start":{"row":2,"column":11},"end":{"row":2,"column":12},"action":"insert","lines":["l"]},{"start":{"row":2,"column":12},"end":{"row":2,"column":13},"action":"insert","lines":["a"]},{"start":{"row":2,"column":13},"end":{"row":2,"column":14},"action":"insert","lines":["t"]}],[{"start":{"row":2,"column":10},"end":{"row":2,"column":14},"action":"remove","lines":["flat"],"id":47},{"start":{"row":2,"column":10},"end":{"row":2,"column":17},"action":"insert","lines":["flatten"]}],[{"start":{"row":2,"column":17},"end":{"row":2,"column":18},"action":"insert","lines":["("],"id":48}],[{"start":{"row":2,"column":48},"end":{"row":2,"column":49},"action":"insert","lines":[")"],"id":49}],[{"start":{"row":10,"column":0},"end":{"row":10,"column":1},"action":"insert","lines":["#"],"id":50},{"start":{"row":9,"column":0},"end":{"row":9,"column":1},"action":"insert","lines":["#"]},{"start":{"row":8,"column":0},"end":{"row":8,"column":1},"action":"insert","lines":["#"]},{"start":{"row":7,"column":0},"end":{"row":7,"column":1},"action":"insert","lines":["#"]},{"start":{"row":6,"column":0},"end":{"row":6,"column":1},"action":"insert","lines":["#"]},{"start":{"row":5,"column":0},"end":{"row":5,"column":1},"action":"insert","lines":["#"]},{"start":{"row":4,"column":0},"end":{"row":4,"column":1},"action":"insert","lines":["#"]},{"start":{"row":3,"column":0},"end":{"row":3,"column":1},"action":"insert","lines":["#"]},{"start":{"row":2,"column":0},"end":{"row":2,"column":1},"action":"insert","lines":["#"]},{"start":{"row":1,"column":0},"end":{"row":1,"column":1},"action":"insert","lines":["#"]}],[{"start":{"row":11,"column":0},"end":{"row":11,"column":1},"action":"remove","lines":["#"],"id":51},{"start":{"row":10,"column":0},"end":{"row":10,"column":1},"action":"remove","lines":["#"]},{"start":{"row":9,"column":0},"end":{"row":9,"column":1},"action":"remove","lines":["#"]},{"start":{"row":8,"column":0},"end":{"row":8,"column":1},"action":"remove","lines":["#"]},{"start":{"row":7,"column":0},"end":{"row":7,"column":1},"action":"remove","lines":["#"]}],[{"start":{"row":6,"column":0},"end":{"row":6,"column":1},"action":"remove","lines":["#"],"id":52},{"start":{"row":5,"column":0},"end":{"row":5,"column":1},"action":"remove","lines":["#"]},{"start":{"row":4,"column":0},"end":{"row":4,"column":1},"action":"remove","lines":["#"]},{"start":{"row":3,"column":0},"end":{"row":3,"column":1},"action":"remove","lines":["#"]},{"start":{"row":2,"column":0},"end":{"row":2,"column":1},"action":"remove","lines":["#"]},{"start":{"row":1,"column":0},"end":{"row":1,"column":1},"action":"remove","lines":["#"]}],[{"start":{"row":2,"column":49},"end":{"row":3,"column":49},"action":"insert","lines":["","  value = flatten(module.container[*].ip-address)"],"id":53}],[{"start":{"row":2,"column":2},"end":{"row":2,"column":3},"action":"insert","lines":["/"],"id":54},{"start":{"row":2,"column":3},"end":{"row":2,"column":4},"action":"insert","lines":["/"]}],[{"start":{"row":5,"column":0},"end":{"row":5,"column":4},"action":"remove","lines":["//  "],"id":55}],[{"start":{"row":5,"column":0},"end":{"row":5,"column":1},"action":"insert","lines":[" "],"id":56},{"start":{"row":5,"column":1},"end":{"row":5,"column":2},"action":"insert","lines":[" "]},{"start":{"row":5,"column":2},"end":{"row":5,"column":3},"action":"insert","lines":["/"]},{"start":{"row":5,"column":3},"end":{"row":5,"column":4},"action":"insert","lines":["/"]}],[{"start":{"row":3,"column":10},"end":{"row":3,"column":49},"action":"remove","lines":["flatten(module.container[*].ip-address)"],"id":57}],[{"start":{"row":3,"column":10},"end":{"row":3,"column":11},"action":"insert","lines":["m"],"id":58},{"start":{"row":3,"column":11},"end":{"row":3,"column":12},"action":"insert","lines":["o"]},{"start":{"row":3,"column":12},"end":{"row":3,"column":13},"action":"insert","lines":["u"]}],[{"start":{"row":3,"column":12},"end":{"row":3,"column":13},"action":"remove","lines":["u"],"id":59}],[{"start":{"row":3,"column":12},"end":{"row":3,"column":13},"action":"insert","lines":["d"],"id":60}],[{"start":{"row":3,"column":10},"end":{"row":3,"column":13},"action":"remove","lines":["mod"],"id":61},{"start":{"row":3,"column":10},"end":{"row":3,"column":16},"action":"insert","lines":["module"]}],[{"start":{"row":3,"column":16},"end":{"row":3,"column":17},"action":"insert","lines":["."],"id":62},{"start":{"row":3,"column":17},"end":{"row":3,"column":18},"action":"insert","lines":["c"]},{"start":{"row":3,"column":18},"end":{"row":3,"column":19},"action":"insert","lines":["o"]},{"start":{"row":3,"column":19},"end":{"row":3,"column":20},"action":"insert","lines":["n"]}],[{"start":{"row":3,"column":17},"end":{"row":3,"column":20},"action":"remove","lines":["con"],"id":63},{"start":{"row":3,"column":17},"end":{"row":3,"column":26},"action":"insert","lines":["container"]}],[{"start":{"row":3,"column":26},"end":{"row":3,"column":28},"action":"insert","lines":["[]"],"id":64}],[{"start":{"row":3,"column":27},"end":{"row":3,"column":28},"action":"insert","lines":["*"],"id":65}],[{"start":{"row":3,"column":29},"end":{"row":3,"column":30},"action":"insert","lines":["."],"id":66},{"start":{"row":3,"column":30},"end":{"row":3,"column":31},"action":"insert","lines":["i"]},{"start":{"row":3,"column":31},"end":{"row":3,"column":32},"action":"insert","lines":["p"]}],[{"start":{"row":3,"column":32},"end":{"row":3,"column":33},"action":"insert","lines":["-"],"id":67},{"start":{"row":3,"column":33},"end":{"row":3,"column":34},"action":"insert","lines":["a"]},{"start":{"row":3,"column":34},"end":{"row":3,"column":35},"action":"insert","lines":["d"]},{"start":{"row":3,"column":35},"end":{"row":3,"column":36},"action":"insert","lines":["d"]},{"start":{"row":3,"column":36},"end":{"row":3,"column":37},"action":"insert","lines":["r"]}],[{"start":{"row":3,"column":33},"end":{"row":3,"column":37},"action":"remove","lines":["addr"],"id":68},{"start":{"row":3,"column":33},"end":{"row":3,"column":40},"action":"insert","lines":["address"]}],[{"start":{"row":3,"column":10},"end":{"row":3,"column":11},"action":"insert","lines":["f"],"id":69},{"start":{"row":3,"column":11},"end":{"row":3,"column":12},"action":"insert","lines":["l"]}],[{"start":{"row":3,"column":10},"end":{"row":3,"column":12},"action":"remove","lines":["fl"],"id":70},{"start":{"row":3,"column":10},"end":{"row":3,"column":17},"action":"insert","lines":["flatten"]}],[{"start":{"row":3,"column":17},"end":{"row":3,"column":18},"action":"insert","lines":["("],"id":71}],[{"start":{"row":3,"column":48},"end":{"row":3,"column":49},"action":"insert","lines":[")"],"id":72}]]},"ace":{"folds":[],"scrolltop":0,"scrollleft":60,"selection":{"start":{"row":3,"column":48},"end":{"row":3,"column":48},"isBackwards":true},"options":{"guessTabSize":true,"useWrapMode":false,"wrapToView":true},"firstLineState":0},"timestamp":1641460081951,"hash":"014565962c66d53e2c2cd84aeb35b593532ea334"}