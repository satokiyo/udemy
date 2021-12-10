# 1. Kubernetes Basicsおさらい

# 1.1 マスター・ワーカーアーキテクチャ
![alt text](../imgs/k8s_architecture.png "K8s Architecture")

マスターノード (またはControl Plane): 
- K8sクラスターの頭脳
- 冗長化・Security・Storage・スケーリングなど

ワーカーノード: 
- マスターノードの命令に従ってコンテナを起動・削除
- Metricsをマスターノードに送る
- コンテナのRuntimeがある

# 1.2 マスターノード (Control Plane)

![alt text](../imgs/k8s_master_worker.png "K8s Architecture")

- API server: kubectl CLIからのAPIリクエストを承認して、APIを実行
- Etcd: key-value を保存
- Controller: PodやDeploymentのヘルスチェックなどを行い、保持
- Scheduler: 新Podを作成し、Nodeに割り当てる


# 1.3 ワーカーノード (Data Plane)

- Kubelet: ワーカーノードに起動されているエージェントプロセス。マスターノードと接続し命令を実行
- Container runtime: DockerのRuntime
- Kubectl: CLI


# 1.4 K8s オブジェクト - pod, deployment, service, configmap, serviceaccount, ingress, etc

Pod
![alt text](../imgs/pod.png "K8s pod")

Deployment
![alt text](../imgs/deployment.png "K8s Deployment")

Service
![alt text](../imgs/service.png "K8s Service")
![alt text](../imgs/service_type.png "K8s Service Type")

Ingress
![alt text](../imgs/ingress.png "K8s Ingress")

ConfigMap
![alt text](../imgs/configmap.png "K8s ConfigMap")