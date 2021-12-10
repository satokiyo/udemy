# 9. ServiceEntryを使ってEgress Securityとモニタリングを高める 

Ref:
- https://istio.io/latest/docs/tasks/traffic-management/egress/egress-control/#envoy-passthrough-to-external-services

Egress trafficには、3つのケースがあります:
1. (`demo` profileでは __デフォルト__) Envoy proxyがEgressをPassthrough
2. Service entriesで外部ドメインをIstio Service Registryに登録し、Istioによりコントロールされたaccessを提供
3. Envoy proxyを通さない.


> ALLOW_ANY is the default value, allowing you to start evaluating Istio quickly, without controlling access to external services

しかし、デフォルトではIstioによるMonitoringなどをEgress Trafficに対してできません。


## デフォルトのEgressのPass Throughをテスト
curl podの中のコンテナにシェルで接続し、`www.google.com`をCurlしてみる
```sh
kubectl exec -it curl -n non-istio sh
curl www.google.com -I

# アウトプット
HTTP/1.1 200 OK
Content-Type: text/html; charset=ISO-8859-1
P3P: CP="This is not a P3P policy! See g.co/p3phelp for more info."
Date: Sat, 08 Aug 2020 14:09:03 GMT
Server: gws
X-XSS-Protection: 0
X-Frame-Options: SAMEORIGIN
Transfer-Encoding: chunked
Expires: Sat, 08 Aug 2020 14:09:03 GMT
Cache-Control: private
Set-Cookie: 1P_JAR=2020-08-08-14; expires=Mon, 07-Sep-2020 14:09:03 GMT; path=/; domain=.google.com; Secure
Set-Cookie: NID=204=TuCCwEx9UXjigWGEVcfJQZlyqLnmHn91yCTaAxjtbFfmzdTJ5HO6_GW7Kq_K3UuKF3V02PO_udk41yAKiqEEtfiP5a0XT08vRawUUQbH-newck8gkLPIzca9_slpuutN_XmhO1_ASnf00X5g_qD-oLk3PvLe4pC2ur8IY_-trvc; expires=Sun, 07-Feb-2021 14:09:03 GMT; path=/; domain=.google.com; HttpOnly
```

`kiali` dashboardをチェック
![alt text](../imgs/egress_pass_through.png "")


# 9.1 外部のURLをServiceEntryでMeshに登録

## BEFORE

今度は、curl podの中のコンテナにシェルで接続し、`httpbin.org/headers`をCurlしてみる
```sh
kubectl exec -it curl sh

curl http://httpbin.org/headers
# アウトプット
{
  "headers": {
    "Accept": "*/*", 
    "Content-Length": "0", 
    "Host": "httpbin.org", 
    "User-Agent": "curl/7.71.1-DEV", 
    "X-Amzn-Trace-Id": "Root=1-5f2eb912-f2277b001719c0a887f8f7d0", 
    "X-B3-Sampled": "1", 
    "X-B3-Spanid": "95af8293e68d385b", 
    "X-B3-Traceid": "f1b2518a2400ef3195af8293e68d385b", 
    "X-Envoy-Attempt-Count": "1", 
    "X-Envoy-Peer-Metadata": "ChoKCkNMVVNURVJfSUQSDBoKS3ViZXJuZXRlcwogCgxJTlNUQU5DRV9JUFMSEBoOMTkyLjE2OC43Ny4xMTIKugEKBkxBQkVMUxKvASqsAQoZCgxpc3Rpby5pby9yZXYSCRoHZGVmYXVsdAoNCgNydW4SBhoEY3VybAokChlzZWN1cml0eS5pc3Rpby5pby90bHNNb2RlEgcaBWlzdGlvCikKH3NlcnZpY2UuaXN0aW8uaW8vY2Fub25pY2FsLW5hbWUSBhoEY3VybAovCiNzZXJ2aWNlLmlzdGlvLmlvL2Nhbm9uaWNhbC1yZXZpc2lvbhIIGgZsYXRlc3QKGgoHTUVTSF9JRBIPGg1jbHVzdGVyLmxvY2FsCg4KBE5BTUUSBhoEY3VybAoWCglOQU1FU1BBQ0USCRoHZGVmYXVsdAo8CgVPV05FUhIzGjFrdWJlcm5ldGVzOi8vYXBpcy92MS9uYW1lc3BhY2VzL2RlZmF1bHQvcG9kcy9jdXJsChwKD1NFUlZJQ0VfQUNDT1VOVBIJGgdkZWZhdWx0ChcKDVdPUktMT0FEX05BTUUSBhoEY3VybA==", 
    "X-Envoy-Peer-Metadata-Id": "sidecar~192.168.77.112~curl.default~default.svc.cluster.local"
  }
}
```

## AFTER
ServiceEntryに`google.com`と`httpbin.org`を登録

[service_entry_google.com](service_entry_google.com),
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: external-google
spec:
  hosts:
  - google.com # must be FQDN
  - www.google.com
  ports:
  - number: 80
    name: http
    protocol: HTTP
  - number: 443
    name: https
    protocol: HTTPS
  resolution: DNS
  location: MESH_EXTERNAL
---
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: external-httpbin
spec:
  hosts:
  - httpbin.org # <----- for httpbin domain
  ports:
  - number: 80
    name: http
    protocol: HTTP
  - number: 443
    name: https
    protocol: HTTPS
  resolution: DNS
  location: MESH_EXTERNAL
```

アプライ
```
kubectl apply -f service_entry_google.yaml 
```

curl podの中のコンテナにシェルで接続し、`google.com`、`httpbin.org/headers`、`appl.com`にCurlしてみる
```sh
kubectl exec -it curl sh

curl www.google.com

curl http://httpbin.org/headers
# アウトプット
{
  "headers": {
    "Accept": "*/*", 
    "Content-Length": "0", 
    "Host": "httpbin.org", 
    "User-Agent": "curl/7.71.1-DEV", 
    "X-Amzn-Trace-Id": "Root=1-5f2eb947-b8cecf407ff76800c5201900", 
    "X-B3-Sampled": "1", 
    "X-B3-Spanid": "b17f5421562140a7", 
    "X-B3-Traceid": "ef45b3cfa9c8c81cb17f5421562140a7", 
    "X-Envoy-Attempt-Count": "1", 
    "X-Envoy-Decorator-Operation": "httpbin.org:80/*", # <------ Envoy sidecar proxyが追加
    "X-Envoy-Peer-Metadata": "ChoKCkNMVVNURVJfSUQSDBoKS3ViZXJuZXRlcwogCgxJTlNUQU5DRV9JUFMSEBoOMTkyLjE2OC43Ny4xMTIKugEKBkxBQkVMUxKvASqsAQoZCgxpc3Rpby5pby9yZXYSCRoHZGVmYXVsdAoNCgNydW4SBhoEY3VybAokChlzZWN1cml0eS5pc3Rpby5pby90bHNNb2RlEgcaBWlzdGlvCikKH3NlcnZpY2UuaXN0aW8uaW8vY2Fub25pY2FsLW5hbWUSBhoEY3VybAovCiNzZXJ2aWNlLmlzdGlvLmlvL2Nhbm9uaWNhbC1yZXZpc2lvbhIIGgZsYXRlc3QKGgoHTUVTSF9JRBIPGg1jbHVzdGVyLmxvY2FsCg4KBE5BTUUSBhoEY3VybAoWCglOQU1FU1BBQ0USCRoHZGVmYXVsdAo8CgVPV05FUhIzGjFrdWJlcm5ldGVzOi8vYXBpcy92MS9uYW1lc3BhY2VzL2RlZmF1bHQvcG9kcy9jdXJsChwKD1NFUlZJQ0VfQUNDT1VOVBIJGgdkZWZhdWx0ChcKDVdPUktMT0FEX05BTUUSBhoEY3VybA==", 
    "X-Envoy-Peer-Metadata-Id": "sidecar~192.168.77.112~curl.default~default.svc.cluster.local"
  }
}

# access apple.com (not registered with ServiceEntry)
curl apple.com -I -L
```

Istio sidecar Envoy proxyにより、HTTP headerに`X-Envoy-Decorator-Operation`が追加されたのがわかる
```json
"X-Envoy-Decorator-Operation": "httpbin.org:80/*", 
```

Curl pod内のistio sidecar proxyコンテナのlogをチェック
```sh
kubectl logs curl -c istio-proxy | tail

# google.comのログ
[2020-08-08T14:41:49.896Z] "GET / HTTP/1.1" 301 - "-" "-" 0 219 31 31 "-" "curl/7.71.1-DEV" "38bb64b2-fc64-9f00-a745-c468747fb0ee" "google.com" "172.217.3.206:80" outbound|80||google.com 192.168.77.112:55708 172.217.3.206:80 192.168.77.112:55706 - default

# httpbin.orgのログ
[2020-08-08T14:41:39.447Z] "GET /headers HTTP/1.1" 200 - "-" "-" 0 1135 72 72 "-" "curl/7.71.1-DEV" "11727077-f912-9635-bb39-e61a0fc6d152" "httpbin.org" "54.236.246.173:80" outbound|80||httpbin.org 192.168.77.112:40152 3.220.112.94:80 192.168.77.112:32790 - default

# apple.comのログ
[2020-08-08T14:45:32.584Z] "HEAD / HTTP/1.1" 301 - "-" "-" 0 0 156 156 "-" "curl/7.71.1-DEV" "04b5245d-e015-98a6-95c3-97cd387936b8" "apple.com" "17.172.224.47:80" PassthroughCluster 192.168.77.112:48844 17.172.224.47:80 192.168.77.112:48842 - allow_any
```

最初の2つは`outbound|80||google.com `とあるが、ServiceEntryで登録していないApple.comに対しては `PassthroughCluster`となってるのがわかる。

`kiali` dashboardをチェックすると, `external-google`と`external-httpbin`のservice entry アイコンが見える
![alt text](../imgs/egress_service_entry_google.png "")



# 9.2 外部URLへのアクセスに対してTimeoutを設定する
Ref: https://istio.io/latest/docs/tasks/traffic-management/egress/egress-control/#manage-traffic-to-external-services


Virtual ServiceでIncomingリクエストに対してTimeoutを設定したように、Service Entryで登録したドメインへのEgressのTrafficにもTimeoutなどを設定できます。

[virtual_service_httpbin_timeout.yaml](virtual_service_httpbin_timeout.yaml)で, `httpbin.org`へのリクエストに3秒の timeoutを設定。

__注意__: `gateways`のリストで`bookinfo-gateway`しか選択していない場合はうまくいきません。EgressのリクエストはPodから出ていくので、`mesh`を`gateways`に追加するか、完全に`gateways`を指定しない（この場合、デフォルトで、`bookinfo-gateway`と`mesh`の両方に適用される）かどちらかにします。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin-org
spec:
  hosts: 
  - httpbin.org
  # gateways: # gatewaysを指定しない（この場合、デフォルトで、`bookinfo-gateway`と`mesh`の両方に適用される）
  # - bookinfo-gateway # <----- `bookinfo-gateway`しか選択していない場合はうまくいきません
  http: 
  - timeout: 3s
    route:
      - destination:
          host: httpbin.org # <---- destinatonは、Service Registryに存在すればinternalとexternalのどちらでも構わない
        weight: 100
```

アプライ
```
kubectl apply -f virtual_service_httpbin_timeout.yaml
```

`httpbin.org/delay/5`にCurlコンテナからアクセスし、5秒後にReturnするようにする
```sh
kubectl exec -it curl sh

# time コマンドを使って、リスポンスを計測
time curl httpbin.org/delay/5 -I

# アウトプット
HTTP/1.1 504 Gateway Timeout # <------ HTTP 504
content-length: 24
content-type: text/plain
date: Sat, 08 Aug 2020 16:35:36 GMT
server: envoy

real    0m 3.00s # <----- 3秒後にTimeoutしてReturnされたのがわかる
user    0m 0.00s
sys     0m 0.00s
```

httpbin.orgが5秒後にReturnするはずだったが, Istioが3秒後にTimeoutでリスポンスを返したのがわかります。



# 9.3 外部URLへのアクセスに対して、DestinationRuleでHTTPSを有効化する（TLS Origination）
Ref: https://istio.io/latest/docs/tasks/traffic-management/egress/egress-tls-origination/

## BEFORE

まずはMesh外の`http://www.apple.com:80`にMesh内からアクセスしてみると、`HTTP 301: Moved Permanently`が返ってくるのがわかる。

`curl -L`でRedirectのLocationをフォローすると、２回目のHTTP requestで`www.apple.com:80`から`https://www.apple.com:443`にRedirectされる。

```sh
kubectl exec -it curl sh

curl www.apple.com -I -L

# １回目のHTTP request
HTTP/1.1 301 Moved Permanently # <------ 301
server: envoy
content-length: 0
location: https://www.apple.com/ # <------ HTTPSへredirectされている
cache-control: max-age=0
expires: Sat, 08 Aug 2020 17:05:20 GMT
date: Sat, 08 Aug 2020 17:05:20 GMT
strict-transport-security: max-age=31536000
set-cookie: geo=US; path=/; domain=.apple.com
set-cookie: ccl=QO0eGkc3ptNP9wG4TcYeqLpwm47hI4Fn2D1OgPu2lWC0l4e8+u4NcbyLmWf2dYE9stLV3SW1GVKt0GN9ux4DEKwFB1xjgLhYHB4sKrxAkm8PTWq6PoAD5HAL3a5QX4SrluWpftjq3OARqync1M+C5ngjPFWBgvdYyMjYLo63908=; path=/; domain=.apple.com
x-envoy-upstream-service-time: 19

# ２回目のHTTP request
HTTP/2 200 
server: Apache
x-frame-options: SAMEORIGIN
x-xss-protection: 1; mode=block
accept-ranges: bytes
x-content-type-options: nosniff
content-type: text/html; charset=UTF-8
strict-transport-security: max-age=31536000; includeSubDomains
content-length: 69376
cache-control: max-age=254
expires: Sat, 08 Aug 2020 16:54:51 GMT
date: Sat, 08 Aug 2020 16:50:37 GMT
set-cookie: geo=US; path=/; domain=.apple.com
```

つまり __HTTP requestsが２回__ 送られているのがわかります。

これを __TLS origination__ を使って, １回目のリクエストからHTTPSで外部に接続し、__２回目のリクエストを省く__ ことができます。


## AFTER

### Step 1: Create ServiceEntry for external "apple.com" so we can control requests

[service_entry_apple.yaml](service_entry_apple.yaml)で、 port 80と443のEgressを定義
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: apple-com
spec:
  hosts:
  - apple.com
  - www.apple.com
  ports:
  - number: 80
    name: http-port
    protocol: HTTP
  - number: 443
    name: https-port-for-tls-origination
    protocol: HTTPS
  resolution: DNS
```

アプライ
```
kubectl apply -f service_entry_apple.yaml
```


### Step 2: "apple.com"ドメインのVirtualServiceを作り、DestinationRuleで定義されたSubsetを指定する

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: apple-com
spec:
  hosts:
  - "*.apple.com"
  http:
  - match:
    - port: 80 # <-----　Port８０のEgressに対して
    route:
    - destination:
        host: www.apple.com
        subset: tls-origination # <-----　DestinationRuleで定義されたSubsetへ、Port 443でRouting
        port:
          number: 443
```

アプライ
```
kubectl apply -f virtual_service_apple.yaml
```


### Step 3: DestinationRuleでTLSコネクションを開始するよう設定

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: apple-com
spec:
  host: www.apple.com
  subsets:
  - name: tls-origination
    trafficPolicy:
      loadBalancer:
        simple: ROUND_ROBIN
      portLevelSettings:
      - port:
          number: 443
        tls:
          mode: SIMPLE # HTTPSコネクションでwww.apple.comに対して接続
```

アプライ
```
kubectl apply -f destination_rule_apple_tls.yaml
```

### Step 4: "http://apple.com:80"へのアクセスが、１回のリクエストで"https://www.apple.com:443"に送られるかテスト

```sh
kubectl exec -it curl sh

curl http://www.apple.com:80 -I

# successful アウトプット
HTTP/1.1 200 OK # <----- Redirectされることなく、１回目のRequestで２００が返ってくる
server: envoy
x-frame-options: SAMEORIGIN
x-xss-protection: 1; mode=block
accept-ranges: bytes
x-content-type-options: nosniff
content-type: text/html; charset=UTF-8
strict-transport-security: max-age=31536000; includeSubDomains
content-length: 69376
cache-control: max-age=175
expires: Sat, 08 Aug 2020 17:09:33 GMT
date: Sat, 08 Aug 2020 17:06:37 GMT
set-cookie: geo=US; path=/; domain=.apple.com
set-cookie: ccl=++ZFCjF2ffURjVJbF3k90vN6OoR0Bb8bzI5tlhkdQLRgt+cZbIwFYUNL8QvOpCC3bTxAlUg0ENdzYvqE5oYaoQwIqzDORByabBmtTdNAbSEfsQ5CCZloUlDF90NVH9VQzBw2xhnQGk0XlhOuo2zmApMHpmRemvIYqFkDcin+UsM=; path=/; domain=.apple.com
x-envoy-upstream-service-time: 35 
```


# クリーンアップ
```
kubectl delete ns istio-enabled non-istio

kubectl delete -f pod_curl.yaml
```
