# 5. Istio VirtualServiceとGatewayでPodを外部に公開 

## 5.1 Gatewayとは何か（Ingress Controllerの代替）
Refs:
- https://istio.io/latest/docs/reference/config/networking/gateway/
- https://istio.io/latest/docs/concepts/traffic-management/#gateways

Ingress Controller vs Istio Gateway：
![alt text](../imgs/eks_aws_architecture_with_apps_ingress_istio_gateway.png "")


Gatewayはロードバランサー（Ingress Controllerもそうであるように）:
> Gateway describes a load balancer operating at the edge of the mesh receiving incoming or outgoing HTTP/TCP connections

また, gateway Pod内には __standalone__ のEnvoy proxyがDeployされている:
> Gateway configurations are applied to standalone Envoy proxies that are running at the edge of the mesh, rather than sidecar Envoy proxies running alongside your service workloads.

`istio-system`Namespace内の`ingressgateway`Podをリストアップ
```
kubectl get pod -n istio-system -l istio=ingressgateway
NAME                                    READY   STATUS    RESTARTS   AGE
istio-ingressgateway-5d869f5bbf-bvpxs   1/1     Running   0          7d20h
```

`1/1`のコラムを見ると,　このPodには1つだけコンテナがあるのがわかります。これゆえに __standalone envoy proxy__ と呼ばれています。もしこれが __sidecar proxy__ の場合、Pod内には2つのコンテナ（アプリのコンテナとEnvoy proxyコンテナ）があるので`2/2`と表示されます。


Gatewayの役割は、 __AWS ELB Listener__ やK8s Ingress Controllerと似ていて、 __incoming__ ports, protocol, そしてtarget groupsを定義します。



# 5.2 Gateway YAMLの解剖
例えば、下記のYAMLは
- `istio: ingressgateway`のlabelがあるPod内にあるEnvoy proxyにConfigが設定される
- "*"（ワイルドカード）のホスト向けのHTTPトラフィックをport 80を通して、Service Mesh内に受け入れる

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: bookinfo-gateway
spec:
  selector:
    istio: ingressgateway # `istio-system` namespace内にあるdefault istio gateway proxyを選択
  servers:
  - port:
      number: 80  # incoming portを定義
      name: http # label assigned to the port
      protocol: HTTP # incoming protocolを定義（HTTP|HTTPS|GRPC|HTTP2|MONGO|TCP|TLS）
    hosts: # このgatewayで外部公開するDNSホスト
    - "*"
```

しかし、Gatewayが正常に起動するためには, __virtual service__ をGatewayにバインドする必要があります(次のセクション)。


AWS ELB Listener, Target Groupと、Istio Gateway, Virtual Serviceの比較:
- AWS ELB Listener -> Istio Gateway
- AWS __ELB Target Group__ (Backendの L7 path/host, protocol, backendsを定義) -> Istio __Virtual Service__ (L7 path/host, protocol, TLS、BackendのK8s serviceなどを定義)



# 5.3 Virtual Serviceとは何か
Ref: https://istio.io/latest/docs/concepts/traffic-management/#virtual-services


Ingress ControllerとIstio Gatewayの比較:
![alt text](../imgs/eks_aws_architecture_with_apps_ingress_istiod.png "")

TrafficのFlow：
![alt text](../imgs/istio_gw_vs_svc2.png "")


`VirtualService`を使うことでRoutingをCustomizeできます。
例えば、
- 20% のTrafficを新バージョンのPodへ流したい (canary)
- HTTP headerのこのユーザーにはversion 2へRoutingしたい
- 30%のリクエストに対して HTTP 400をリターンしたい (fault injection)
- 10%のリクエストに対して5秒のtimeoutを設定したい
- など



# 5.4 VirtualService YAMLの解剖
Ref: https://istio.io/latest/docs/concepts/traffic-management/#virtual-service-example

下記のVirtualService yaml:
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService 
metadata:
  name: reviews
spec:
  hosts: # Routing ルールがApplyされるホストのリスト
  - reviews
  http:
  - match: # <---- Routingの条件Match
    - headers:
        end-user: 
          exact: jason # <--- http headerに”end-user: jason"がある時
    route: # <---- routiung config
    - destination:
        host: reviews
        subset: v2 # <--- http headerに”end-user: jason"がある時は、reviews v2へRouting
  - route:
    - destination:
        host: reviews # Backendのホスト名（Kubernetes short nameかFQDNか、Istio Service Entryに登録された外部ホスト）
        subset: v3 # <---- それ以外のroutiung configはreviews v3ヘRouting
```

- host
    - IPアドレスかDNS name（Kubernetes service short nameかFQDNか、仮想のDNSも可能）、もしくわwildcard (”*”)の prefixeも可能。 
- http
    - Match condition
    - Route destination 
        -  存在するホスト名（K8sのService名か、PublicのDNS）。 Virtual service’s host(s)と違って、このホスト名はIstioのservice registryに登録されているホスト名である必要がある。Istio Service Mesh内に存在するK8sのService名か、 __Istio Service Entryで登録された外部のホスト__ (例：AWS RDS endpoint）

#### 注釈: 
1. K8s serviceのshort name (例: `reviews`。このFQDNは`reviews.default.svc.cluster.local`)が使えるのは、VirtualServiceとK8s Serviceのnamespaceが同じ時、そうでない場合は、VirtualServiceのNamespaceがK8s serviceのshort nameに追加される（例: VirtualServiceが`test` namespaceで、`reviews`のShort nameを使うと、もしその`reviews` serviceが`default` namespaceにあって `test` namespaceにはなくても、Istioは`test` namespaceを`reviews`に追加するので、`reviews.test.svc.cluster.local`となってしまう）
2. Routingルールは上から下へ順番にEvaluateされる



# 5.5 Istio Gateway (Ingress controllerの代替)とVirtual Service (ingress resourceの代替)をディプロイ

[bookinfo_ingress_gateway.yaml](bookinfo_ingress_gateway.yaml)をチェック
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: guestbook-gateway
  namespace: default
spec:
  selector:
    istio: ingressgateway # `istio-system` namespace内にあるdefault istio gateway proxyを選択
  servers: # defines L7 host, port, and protocol
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts: # このgatewayで外部公開するDNSホスト
    - "*"
```

[bookinfo_virtualservice.yaml](bookinfo_virtualservice.yaml)もチェック
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: guestbook-virtualservice
  namespace: default
spec:
  hosts: # Routing ルールがApplyされるホストのリスト
  - "*"
  gateways:
  - guestbook-gateway.default.svc.cluster.local # Gatewayにバインド
  http:  # L7 load balancing by http path and host, just like K8s ingress resource
  - match:
    - uri:
        prefix: /
        prefix: /guestbook
    route:
    - destination:
        host: guestbook.default.svc.cluster.local # Backendのホスト名（Kubernetes short nameかFQDNか、Istio Service Entryに登録された外部ホスト）
        port:
          number: 3000 # <--- guestbook service port
```

ディプロイ
```sh
kubectl apply -f gateway_guestbook.yaml
kubectl apply -f virtualservice_guestbook.yaml

# check them
kubectl get virtualservice,gateway
```

istio ingressgateway serviceのPublic IP (i.e. AWS ELB DNS)を取得
```sh
kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# public ELB endpointをcurlする
curl -v $(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# アウトプット
* Rebuilt URL to: a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com/
*   Trying 54.149.143.27...
* TCP_NODELAY set
* Connected to a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com (54.149.143.27) port 80 (#0)
> GET / HTTP/1.1
> Host: a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com
> User-Agent: curl/7.54.0
> Accept: */*
> 
< HTTP/1.1 200 OK # <---- HTTP 200
< accept-ranges: bytes
< content-length: 922
< content-type: text/html; charset=utf-8
< last-modified: Wed, 16 Dec 2015 18:26:32 GMT
< date: Sun, 02 Aug 2020 07:46:37 GMT
< x-envoy-upstream-service-time: 1
< server: istio-envoy
```

`kiali` dashboardをチェック
```
istioctl dashboard kiali
```

![alt text](../imgs/guestbook_kiali_1.png "Kiali")


TrafficがVirtual Service (紫のアイコン)からbackendのguestbook podにmutual TLS（鍵アイコン）でコネクトされているのがわかる。

![alt text](../imgs/guestbook_kiali_2.png "Kiali")



# 5.6 Nginx Ingress Controller (とAWS ELB)をアンインストール
Istio Ingress GatewayとAWS ELBが作成されたので, K8s ingress controllerをアンインストール 

```sh
helm uninstall nginx-ingress-controller -n nginx-ingress-controller

# アウトプット
release "nginx-ingress-controller" uninstalled
```

`nginx-ingress-controller` namespaceのリソースが削除されたかチェック
```sh
kubectl get all -n nginx-ingress-controller

# アウトプット
No resources found.

# delete namespace
kubectl delete ns nginx-ingress-controller

# delete ingress
kubectl delete ingress guestbook
```

この時点で、AWS ELBはistio ingressgateway serviceで作られたもの1つだけであることをチェック
![alt text](../imgs/aws_elb_console.png "Kiali")


# 5.7 他のサンプルアプリBookinfoをディプロイ
まずはguestbook appsを削除
```
kubectl delete rc,svc,vs,gateway,ingress --all
```

bookinfoアプリをDeploy
```sh
# deploymentとserviceを作成
kubectl apply -f bookinfo.yaml 
```

istio GatewayとVirtualServiceで外部公開
```sh
kubectl apply -f gateway_bookinfo.yaml
kubectl apply -f virtualservice_bookinfo.yaml 
```

bookinfoのPublic endpointを取得
```
curl -v $(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')/productpage
```

ブラウザーからアクセス
```sh
echo $(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')/productpage

# ブラウザーからアクセス
a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com/productpage
```

![alt text](../imgs/bookinfo_ui.png "")

Kiali dashboardをチェック
![alt text](../imgs/bookinfo_kiali.png "")

