# 2. Istioをインストール
# 2.1 istioctlを使ってIstioをインストール
```sh
# まずは istioctl CLIをインストール
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.6.6 sh -
cd istio-1.6.6
echo "export PATH=$PWD/bin:$PATH" >> ~/.bash_profile

# 新しいシェルWindowを開き、 PATH変数を再読み込み
```


# 2.2 istio config profileを使ってIstioを K8s クラスター内にインストール 
Ref: https://istio.io/latest/docs/setup/additional-setup/config-profiles/

テンプレート的にPresetされた、インストール可能なprofilesがいくつかあります:
- default
- dmeo
- minimal
- etc

![alt text](../imgs/istio_profile.png "Istio")

このデモでは最も総括的な`demo` profileをインストールします。　このProfileで、ingress/egress gateways, grafana, kiali, jaegger (request tracing), そして prometheus monitoring/metrics dashboardsなどもDeployされます。

```sh
# profilesをリストアップ
istioctl profile list

# ”demo”　ProfileのConfigをyamlに保存
istioctl profile dump demo > profile_demo_config.yaml
```

アウトプット
```sh
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  addonComponents:
    grafana:
      enabled: true
      k8s:
        replicaCount: 1
    istiocoredns:
      enabled: false
    kiali:
      enabled: true
      k8s:
        replicaCount: 1
    prometheus:
      enabled: true
      k8s:
        replicaCount: 1
    tracing:
      enabled: true
  components:
    base:
      enabled: true
    citadel:
      enabled: false
      k8s:
        strategy:
          rollingUpdate:
            maxSurge: 100%
            maxUnavailable: 25%
    cni:
      enabled: false
    egressGateways:
    - enabled: true
      k8s:
        resources:
          requests:
            cpu: 10m
            memory: 40Mi
      name: istio-egressgateway
```

k8s manifestファイルをGenerate
```sh
istioctl manifest generate \
  --set profile=demo \
  --set values.gateways.istio-ingressgateway.sds.enabled=true \
  > generated-manifest-demo.yaml
```

インストール
```sh
istioctl install --set profile=demo
```

アウトプット
<details><summary>show</summary><p>

```sh
✔ Istio core installed                                        ✔ Istiod installed  
✔ Ingress gateways installed
✔ Egress gateways installed                                   ✔ Addons installed                                            ✔ Installation complete
```
</p></details>


Istio configurationをAnalyzeして正しくインストールされたかチェック
```sh
istioctl analyze --all-namespaces

# アウトプット
Warn [IST0102] (Namespace default) The namespace is not enabled for Istio injection. Run 'kubectl label namespace default istio-injection=enabled' to enable it, or 'kubectl label namespace default istio-injection=disabled' to explicitly mark it as not needing injection
Warn [IST0102] (Namespace kube-node-lease) The namespace is not enabled for Istio injection. Run 'kubectl label namespace kube-node-lease istio-injection=enabled' to enable it, or 'kubectl label namespace kube-node-lease istio-injection=disabled' to explicitly mark it as not needing injection
Error: Analyzers found issues when analyzing all namespaces.
See https://istio.io/docs/reference/config/analysis for more information about causes and resolutions.
```

作成されたPodやServiceを表示
```sh
kubectl get pod,svc -n istio-system

# アウトプット
NAME                                        READY   STATUS    RESTARTS   AGE
pod/grafana-5cc7f86765-krwvf                1/1     Running   0          5m51s
pod/istio-egressgateway-5c8f9897f7-sfqg6    1/1     Running   0          29m
pod/istio-ingressgateway-65dd885d75-bbqtn   1/1     Running   0          29m
pod/istio-tracing-8584b4d7f9-whwjr          1/1     Running   0          5m39s
pod/istiod-7d6dff85dd-w5szx                 1/1     Running   0          29m
pod/kiali-696bb665-sngrt                    1/1     Running   0          5m43s
pod/prometheus-564768879c-w55nb             2/2     Running   0          5m39s

NAME                                TYPE           CLUSTER-IP       EXTERNAL-IP                                                              PORT(S)                                                                                                                                      AGE
service/grafana                     ClusterIP      172.20.151.105   <none>                                                                   3000/TCP                                                                                                                                     5m50s
service/istio-egressgateway         ClusterIP      172.20.208.92    <none>                                                                   80/TCP,443/TCP,15443/TCP                                                                                                                     29m
service/istio-ingressgateway        LoadBalancer   172.20.170.225   aa7cfd0021476452ba8c3836365f2df3-478100139.us-east-1.elb.amazonaws.com   15020:31474/TCP,80:30046/TCP,443:31013/TCP,15029:31841/TCP,15030:31961/TCP,15031:30599/TCP,15032:30637/TCP,31400:31608/TCP,15443:32324/TCP   29m
service/istio-pilot                 ClusterIP      172.20.97.20     <none>                                                                   15010/TCP,15011/TCP,15012/TCP,8080/TCP,15014/TCP,443/TCP                                                                                     29m
service/istiod                      ClusterIP      172.20.236.155   <none>                                                                   15012/TCP,443/TCP                                                                                                                            29m
service/jaeger-agent                ClusterIP      None             <none>                                                                   5775/UDP,6831/UDP,6832/UDP                                                                                                                   5m35s
service/jaeger-collector            ClusterIP      172.20.177.164   <none>                                                                   14267/TCP,14268/TCP,14250/TCP                                                                                                                5m37s
service/jaeger-collector-headless   ClusterIP      None             <none>                                                                   14250/TCP                                                                                                                                    5m36s
service/jaeger-query                ClusterIP      172.20.116.249   <none>                                                                   16686/TCP                                                                                                                                    5m38s
service/kiali                       ClusterIP      172.20.253.248   <none>                                                                   20001/TCP                                                                                                                                    5m45s
service/prometheus                  ClusterIP      172.20.101.184   <none>                                                                   9090/TCP                                                                                                                                     5m41s
service/tracing                     ClusterIP      172.20.143.171   <none>                                                                   80/TCP                                                                                                                                       5m33s
service/zipkin                      ClusterIP      172.20.170.147   <none>                                                                   9411/TCP                                          
```


`istio-system` namespace内の`istio-ingressgateway`Serviceが AWS ELB（クラシックロードバランサー）を作ったのがわかる
```
service/istio-ingressgateway        LoadBalancer   10.100.229.231   a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com   15020:32676/TCP,80:32703/TCP,443:30964/TCP,31400:30057/TCP,15443:32059/TCP   15m
```

istio ingress gateway serviceによって作られたAWS ELBをAWS Consoleからチェック

![alt text](../imgs/ingress_gateway_aws_elb.png "Istio")


また`istiod-7d6dff85dd-w5szx`Podも作成されているのがわかります。これはIstioのControl Planeコンポーネント（istio pilot (service discovery), Galley (config), sidecar injector）の集合体に立っているPodです。
> istiod unifies functionality that Pilot, Galley, Citadel and the sidecar injector previously performed, into a single binary



# 2.3 Istio Sidecar Injectionを有効化する

K8s namespaceにlabel(`istio-injection=enabled`)を追加し、アプリがDeployされた時に、Istioが自動的にEnvoy sidecar proxiesをInjectするようにします
```sh
# default namespaceをDescribe
kubectl describe ns default

# アウトプット
Name:         default
Labels:       <none>
Annotations:  <none>
Status:       Active
No resource quota.
No resource limits.

# default namespaceにlabelを追加し、Istio Sidecar Injectionを有効化する
kubectl label namespace default istio-injection=enabled

# アウトプット
Name:         default
Labels:       istio-injection=enabled
Annotations:  <none>
Status:       Active
No resource quota.
No resource limits.

# もし無効化する場合
# kubectl label namespace default istio-injection-
```

