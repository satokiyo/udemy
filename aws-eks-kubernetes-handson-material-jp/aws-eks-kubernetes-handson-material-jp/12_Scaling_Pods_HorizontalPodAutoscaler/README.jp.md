
## 12. (ベストプラクティス) Scaling: Horizontal Pod Autoscaler (HPA、水平オートスケーリング)

![alt text](../imgs/hpa.png "HPA")

# ステップ1: Metrics serverをHelm chartでインストール
HPAを使うには、まずmetrics serverがディプロイする必要があります。

Metrics Serverがインストールされたら、プロセスリソースを表示できます
```sh
# nodesのCPU/memory使用料をチェック
kubectl top nodes 

# PodsのCPU/memory使用料をチェック
kubectl top pods
```


# ステップ2: リソースリクエストをPodのYAMLに定義

もし`unable to fetch pod metrics for pod default/eks-demo-74954f798-cnnvb: no metrics known for pod`というエラーがPodをdescribeした時に表示されている場合は、Metrics Serverがインストールされてないか、Pod YAMLにリソースリクエストが定義されていない可能性があります。
```sh
$ kubectl logs metrics-server-5fb44bc684-8xdjq -n kube-system

# アウトプット
I0519 10:04:00.168107       1 serving.go:312] Generated self-signed cert (/tmp/apiserver.crt, /tmp/apiserver.key)
I0519 10:04:00.844946       1 secure_serving.go:116] Serving securely on [::]:8443
E0519 10:04:40.993273       1 reststorage.go:160] unable to fetch pod metrics for pod default/eks-demo-74954f798-cnnvb: no metrics known for pod
E0519 10:04:56.005862       1 reststorage.go:160] unable to fetch pod metrics for pod default/eks-demo-74954f798-cnnvb: no metrics known for pod
```


# Horizontal Pod Autoscalerリソースを作成

まずはテストDeploymentを作成
```
kubectl apply -f test-hpa.yaml
```

Serviceも作成
```
kubectl expose deploy test-hpa --port 80 --dry-run -o yaml > svc.yaml

kubectl apply -f svc.yaml
```

`test-hpa` nginx serviceに接続できるか、別のcurl podからCurlテスト
```sh
kubectl run curl --image curlimages/curl -it sh

curl test-hpa

# アウトプット
<h1>Welcome to nginx!</h1>
```

HPAリソースを作成
```
$ kubectl autoscale deployment test-hpa \
    --min 1 \
    --max 7 \
    --cpu-percent=80 \
    --namespace default \
    --dry-run \
    -o yaml > hpa.yaml

$ kubectl apply -f hpa.yaml
$ kubectl get hpa 
```

アウトプット
```
NAME       REFERENCE             TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
test-hpa   Deployment/test-hpa   <unknown>/80%   1         7         0          4s
```

__TARGETSコラムの2つのパーセンテージが表示されるまで３分ほど待つ__

`TARGETS` コラムに2つのMetrics`0%/50%`（現在のPodのCPU％/スケーリングが開始されるレベルのCPU％）が表示されます。


# HPAをストレステスト 
Apache Benchコマンドを使ってPodに大量のTrafficを送り、スケールアウトするかテスト。
```
kubectl run apache-bench -it --rm \
  --image=httpd \
  --restart Never \
  -- ab -n 500000000 -c 1000 test-hpa/


kubectl run -it --rm load-generator  \
  --restart Never \
  --image=busybox /bin/sh

while true; do wget -q -O- test-hpa:80; done
```

HPAをチェック
```bash
kubectl get hpa

# アウトプット 
NAME       REFERENCE             TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
test-hpa   Deployment/test-hpa   96%/80%   1         7         2          9m19s
```

Podのリソースをチェック
```
kubectl top pods
```


クリーンアップ
```
kubectl delete -f test-hpa.yaml
kubectl delete svc test-hpa
kubectl delete deploy curl
```