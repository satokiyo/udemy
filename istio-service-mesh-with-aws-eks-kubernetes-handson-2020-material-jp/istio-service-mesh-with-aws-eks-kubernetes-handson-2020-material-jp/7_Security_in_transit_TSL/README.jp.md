# 7. TransitのSecurity(HTTPS)

# 7.1 Istio Gatewayを使って1つのホストへのHTTPS (TLS Termination)を有効化する
Refs:
- https://istio.io/latest/docs/reference/config/networking/gateway/
- https://istio.io/latest/docs/tasks/traffic-management/ingress/secure-ingress/


![alt text](../imgs/istio_gateway_tls.png "")


## Step 1: TLS Certificateを作成

https://istio.io/latest/docs/tasks/traffic-management/ingress/ingress-control/#configuring-ingress-using-an-istio-gateway

このコースではドメインを何も保持していないので、AWSのELBのDNSにワイルドカードをつけた`*.elb.amazonaws.com`をSSLの証明書のホストとして指定します。

```bash
# -x509: self signed certificateを作る
# -newkey rsa:2048: 新しいprivate keyのEncryptionアルゴリズムを定義
# -keyout: 新しい private keyの名前
# -out: Certificateの名前
# -days: サートの有効期限。デフォルトは30日
openssl req \
        -x509 \
        -newkey rsa:2048 \
        -keyout istio-elb.amazonaws.com.key.pem \
        -out istio-elb.amazonaws.com.cert.pem \
        -days 365 \
        -nodes \
        -subj '/CN=*.elb.amazonaws.com'
```

Cert（TLS証明書）のコンテンツを表示
```sh
openssl x509 -in istio-elb.amazonaws.com.cert.pem -text -noout

# アウトプット
Certificate:
    Data:
        Version: 1 (0x0)
        Serial Number: 15293043281836592574 (0xd43bcdd6bc8b4dbe)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN=*.elb.amazonaws.com
        Validity
            Not Before: Jun 14 09:10:37 2020 GMT
            Not After : Jun 14 09:10:37 2021 GMT
        Subject: CN=*.elb.amazonaws.com
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
```


## Step 2: TLS CertをK8s Secretに保存

`gateway-cert-aws-elb-dns`というK8sのSecretを作成し、TLSのプライベートKeyとCertファイルを指定
```
kubectl create -n istio-system \
    secret tls gateway-cert-aws-elb-dns \
    --key=istio-elb.amazonaws.com.key.pem \
    --cert=istio-elb.amazonaws.com.cert.pem
```

## Step 3: TLS SecretをIstio Gateway YAMLから指定

[gateway_https.yaml](gateway_https.yaml),
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: bookinfo-gateway
spec:
  selector: 
    istio: ingressgateway 
  servers: 
  - port:
      number: 80
      name: http 
      protocol: HTTP 
    hosts: 
    - "*.elb.amazonaws.com"
  - port: # <---- HTTPSの設定
      number: 443
      name: https 
      protocol: HTTPS 
    hosts:
    - "*.elb.amazonaws.com" # <----- Gatewayが HTTPS port 443を受け入れるホスト名
    tls:
      mode: SIMPLE
      credentialName: gateway-cert-aws-elb-dns # 証明書を保存したK8s secret
```

新しいServersのコンフィグに注目
```yaml
- port: # <---- HTTPSの設定
    number: 443
    name: https 
    protocol: HTTPS 
  hosts:
  - "*.elb.amazonaws.com" # <----- Gatewayが HTTPS port 443を受け入れるホスト名
  tls:
    mode: SIMPLE
    credentialName: gateway-cert-aws-elb-dns # 証明書を保存したK8s secret
```


アプライ
```
kubectl apply -f gateway_https.yaml
```

## Step 4: HTTPSをテスト

https endpointをCurlする:
<details><summary>show</summary><p>

```sh
# self-signed insecure certを使っているので-kか--insecureをPass
curl -k -v \
    https://$(echo $(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')/productpage)

# successful アウトプット 
*   Trying 34.214.199.244...  # <---- AWS ELB DNS がpublic IPにResolveされた
* TCP_NODELAY set
* Connected to a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com (34.214.199.244) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* Cipher selection: ALL:!EXPORT:!EXPORT40:!EXPORT56:!aNULL:!LOW:!RC4:@STRENGTH
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/cert.pem
  CApath: none
* TLSv1.2 (OUT), TLS handshake, Client hello (1): # <----- TLS handshake
* TLSv1.2 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (IN), TLS handshake, Server key exchange (12):
* TLSv1.2 (IN), TLS handshake, Server finished (14):
* TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
* TLSv1.2 (OUT), TLS change cipher, Client hello (1):
* TLSv1.2 (OUT), TLS handshake, Finished (20):
* TLSv1.2 (IN), TLS change cipher, Client hello (1):
* TLSv1.2 (IN), TLS handshake, Finished (20):
* SSL connection using TLSv1.2 / ECDHE-RSA-CHACHA20-POLY1305
* ALPN, server accepted to use h2
* Server certificate: # <----- TLS certのコンテント
*  subject: CN=*.elb.amazonaws.com # <----- TLS certのホスト
*  start date: Aug  5 11:00:46 2020 GMT
*  expire date: Aug  5 11:00:46 2021 GMT
*  issuer: CN=*.elb.amazonaws.com
*  SSL certificate verify result: self signed certificate (18), continuing anyway.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x7fec0500ba00)
> GET /productpage HTTP/2  # <----- HTTP RequestのHeaderコンテンツ
> Host: a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com 
> User-Agent: curl/7.54.0
> Accept: */*
> 
* Connection state changed (MAX_CONCURRENT_STREAMS updated)! 
< HTTP/2 200   # <----- HTTP ２００　response
< content-type: text/html; charset=utf-8
< content-length: 5179
< server: istio-envoy
< date: Wed, 05 Aug 2020 11:24:39 GMT
< x-envoy-upstream-service-time: 30
< 
<!DOCTYPE html>
<html>
  <head>
    <title>Simple Bookstore App</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
  </head>
  <body>
.
  </body>
</html>
* Connection #0 to host a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com left intact
```
</p></details>

Endpontをbrowserからチェック
```sh
echo $(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')/productpage

# アウトプット
a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com/productpage
```

![alt text](../imgs/gateway_tls_browser_1.png "")

![alt text](../imgs/gateway_tls_browser_2.png "")




# 7.2 複数ホストへのHTTPS (TLS Termination) (SNI) をIstio Gatewayを使って有効化する
Ref: https://istio.io/latest/docs/tasks/traffic-management/ingress/secure-ingress/#configure-a-tls-ingress-gateway-for-multiple-hosts

前のセクションでは1つのホストだけHTTPsを有効化しました（`*.us-west-2.elb.amazonaws.com`）。

もし仮に、別のホスト（`test.sni.com`）へもHTTPSを有効化したい場合どうすればいいでしょうか？

ここでSNI (Server Name Invocation)の登場です。


## Step 1: SNI (Server Name Invocation)とは何か？

SNIは、1つのgateway/load balancer/proxy が __複数の TLS certificates__ を提供可能にするものです。

![alt text](../imgs/sni1.png "")

つまり
```sh
# Singleホスト（ドメイン）の場合
gateway IP --> `*.us-west-2.elb.amazonaws.com`

#　マルチホスト（ドメイン）の場合
gateway IP --> `*.us-west-2.elb.amazonaws.com`
          |
           -->  `test.sni.com`
```


## Step 2: なぜ SNIが必要なのか?

![alt text](../imgs/sni2.png "")

1. TLS/SSL は __Transport layer (L4)__ なので, L7の Application Layer（HTTPのHeader）の情報を見れません
2. Gatewayが __TLS certをクライアントに提供する場合は、HTTP requestにあるhostと一致するTLS証明書を提供しますが（デフォルトでGatewayが1つのドメインのTLSしかない場合）__ , __複数のTLS証明書をGatewayが保持している場合且つ、TLS (L4)ではHTTP header (L7)のホスト・ドメインのValueがわかりません__
3. なので __SNI info__ をL4のデータに追加し、Gatewayがどのドメイン向けのTLS certを提供すればいいかわかるようにします



## Step 3: 別のTLS Certを作成 
self-signed root, intermediary CA, そして server certsとkeyを作成
```sh
# -x509: self signed certificateを作る
# -newkey rsa:2048: 新しいprivate keyのEncryptionアルゴリズムを定義
# -keyout: 新しい private keyの名前
# -out: Certificateの名前
# -days: サートの有効期限。デフォルトは30日
openssl req \
        -x509 \
        -newkey rsa:2048 \
        -keyout istio-elb.sni.com.key.pem \
        -out istio-elb.sni.com.cert.pem \
        -days 365 \
        -nodes \
        -subj '/CN=*.sni.com'  # <----- new domain
```

Certのコンテンツを表示
```sh
openssl x509 -in istio-elb.sni.com.cert.pem -text -noout

# アウトプット
Certificate:
    Data:
        Version: 1 (0x0)
        Serial Number: 11192186715375109859 (0x9b52a284d5c786e3)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN=*.sni.com # <---- Cert's common name is set to *.sni.com
        Validity
            Not Before: Aug  7 06:27:30 2020 GMT
            Not After : Aug  7 06:27:30 2021 GMT
        Subject: CN=*.sni.com
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
```


## Step 4: TLS CertをK8s Secretに保存

今度は`gateway-cert-sni-dns`という名前のSecretにTLS certを保存
```
kubectl create -n istio-system \
    secret tls gateway-cert-sni-dns \
    --key=istio-elb.sni.com.key.pem \
    --cert=istio-elb.sni.com.cert.pem
```

## Step 5: TLS SecretをIstio Gateway YAMLから指定

[gateway_https_sni.yaml](gateway_https_sni.yaml),
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: bookinfo-gateway
spec:
  selector: 
    istio: ingressgateway
  servers: 
  - port:
      number: 80 
      name: http 
      protocol: HTTP 
    hosts: 
    - "*.elb.amazonaws.com"
  - port:  # <------ *.elb.amazonaws.com向けのHTTPSコンフィグ
      number: 443
      name: https 
      protocol: HTTPS
    hosts:
    - "*.elb.amazonaws.com"
    tls:
      mode: SIMPLE
      credentialName: gateway-cert-aws-elb-dns
  - port: # <------ *.sni.com向けのHTTPSコンフィグ
      number: 443
      name: https-sni  # <----- ”https”は*.elb.amazonaws.com向けのHTTPSコンフィグで使われているので、被らない名前にする必要がある
      protocol: HTTPS 
    hosts:
    - "*.sni.com" # <----- ドメインを指定
    tls:
      mode: SIMPLE
      credentialName: gateway-cert-sni-dns # 証明書を保存したK8s secret
```

新しいServersのコンフィグに注目
```yaml
  - port: # <------ *.sni.com向けのHTTPSコンフィグ
      number: 443
      name: https-sni  # <----- ”https”は*.elb.amazonaws.com向けのHTTPSコンフィグで使われているので、被らない名前にする必要がある
      protocol: HTTPS 
    hosts:
    - "*.sni.com" # <----- ドメインを指定
    tls:
      mode: SIMPLE
      credentialName: gateway-cert-sni-dns # 証明書を保存したK8s secret
```


アプライ
```
kubectl apply -f gateway_https_sni.yaml
```

`Kiali` DashboardでConfigが正しいかチェックできます
```
istioctl dashboard kiali
```

![alt text](../imgs/kiali_gateway_https_sni_config_1.png "")
![alt text](../imgs/kiali_gateway_https_sni_config_2.png "")


## Step 6: *.sni.comをVirtual ServiceのHostリストに追加

[virtual_service_httpbin_sni.yaml](virtual_service_httpbin_sni.yaml),
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "*.elb.amazonaws.com"
  - httpbin
  - "*.sni.com" # <----- 新しいドメインを追加
  gateways: 
  - bookinfo-gateway 
  http: 
  - match:
    - uri:
        exact: /
      ignoreUriCase: true
    - uri:
        exact: /ip
      ignoreUriCase: true
    - uri:
        exact: /headers
      ignoreUriCase: true
    route:
    - destination:
        host: httpbin.default.svc.cluster.local
        port:
          number: 80
```

アプライ
```
kubectl apply -f virtual_service_httpbin_sni.yaml 
```

```sh
# テスト用のhttpbin podを作成
kubectl apply -f pod_httpbin.yaml

# httpbin podをクラスター内にServiceで公開  
kubectl expose pod httpbin --port 80
```


## Step 7: *.sni.comへのHTTPSをテスト

### SNI前
Regressionがないか、”elb.amazonaws.com”へのHTTPSをまずテスト

<details><summary>show</summary><p>

```sh
# self-signed insecure certを使っているので-kか--insecureをPass
curl -k -v \
    https://$(echo $(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')/productpage)

# もしくわ
curl \
  -HHost:test.elb.amazonaws.com \
  --resolve "test.elb.amazonaws.com:$SECURE_INGRESS_PORT:$(host $(echo $INGRESS_HOST) | tail -1 | awk '{ print $4 }')" \
  "https://test.elb.amazonaws.com:$SECURE_INGRESS_PORT/productpage" 

# successful アウトプット 
*   Trying 34.214.199.244... 
* TCP_NODELAY set
* Connected to a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com (34.214.199.244) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* Cipher selection: ALL:!EXPORT:!EXPORT40:!EXPORT56:!aNULL:!LOW:!RC4:@STRENGTH
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/cert.pem
  CApath: none
* TLSv1.2 (OUT), TLS handshake, Client hello (1): 
* TLSv1.2 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (IN), TLS handshake, Server key exchange (12):
* TLSv1.2 (IN), TLS handshake, Server finished (14):
* TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
* TLSv1.2 (OUT), TLS change cipher, Client hello (1):
* TLSv1.2 (OUT), TLS handshake, Finished (20):
* TLSv1.2 (IN), TLS change cipher, Client hello (1):
* TLSv1.2 (IN), TLS handshake, Finished (20):
* SSL connection using TLSv1.2 / ECDHE-RSA-CHACHA20-POLY1305
* ALPN, server accepted to use h2
* Server certificate: # <----- TLS cert content
*  subject: CN=*.elb.amazonaws.com # <----- TLS cert common name (domain)
*  start date: Aug  5 11:00:46 2020 GMT
*  expire date: Aug  5 11:00:46 2021 GMT
*  issuer: CN=*.elb.amazonaws.com
*  SSL certificate verify result: self signed certificate (18), continuing anyway.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x7fec0500ba00)
> GET /productpage HTTP/2  # <----- HTTP Request Header contents
> Host: a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com # <--- header host matching with *.us-west-2.elb.amazonaws.com
> User-Agent: curl/7.54.0
> Accept: */*
> 
* Connection state changed (MAX_CONCURRENT_STREAMS updated)! 
< HTTP/2 200   # <----- HTTP response
< content-type: text/html; charset=utf-8
< content-length: 5179
< server: istio-envoy
< date: Wed, 05 Aug 2020 11:24:39 GMT
< x-envoy-upstream-service-time: 30
< 
```
</p></details>

TLS certのコンテンツを確認
```sh
* Server certificate: # <----- TLS cert content
*  subject: CN=*.elb.amazonaws.com # <----- TLS cert common name (domain)

> Host: a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com # <--- header host matching with *.us-west-2.elb.amazonaws.com
```


### SNI後
`*.sni.com`へのHTTPSをテスト

```sh
SECURE_INGRESS_PORT=443

# 注意: もしPublic Cloud（AWSやGCP）を使っている場合は、ロードバランサーのDNS（IPでなく）がK8sのServiceアウトプットで表示されます。なので、$INGRESS_HOSTがIP出なくDNS hostにResolveされる場合、CurlのArgumentである --resolveを使って、"test.sni.com:$SECURE_INGRESS_PORT"の部分を$INGRESS_HOSTにResolveするようにしてもうまく作動しません！
export INGRESS_HOST=$(echo $(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'))
echo $INGRESS_HOST

# この場合、$INGRESS_HOSTのDNSをまずIPにResolveするために、$(host $(echo $INGRESS_HOST) | tail -1 | awk '{ print $4 }')を使います。
# 参照: https://unix.stackexchange.com/questions/33121/curl-resolve-appears-to-do-nothing
export INGRESS_PUBLIC_IP=$(host $(echo $INGRESS_HOST) | tail -1 | awk '{ print $4 }')
echo $INGRESS_PUBLIC_IP

# CurlのArgumentである --resolveを使って、"test.sni.com:$SECURE_INGRESS_PORT"の部分を$INGRESS_PUBLIC_IP にResolveするように指定する
curl -v \
  -HHost:test.sni.com \
  --resolve "test.sni.com:$SECURE_INGRESS_PORT:$INGRESS_PUBLIC_IP" \
  "https://test.sni.com:$SECURE_INGRESS_PORT/headers" -k

# もしくわ（-HHostなしでも可能）
curl -v \
  --resolve "test.sni.com:$SECURE_INGRESS_PORT:$INGRESS_PUBLIC_IP" \
  "https://test.sni.com:$SECURE_INGRESS_PORT/headers" -k

# 注意：$INGRESS_HOST がpublic IPでない場合、下記はうまくいきません
curl -v \
  --resolve "test.sni.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
  "https://test.sni.com:$SECURE_INGRESS_PORT/headers" -k


# アウトプット
* Added test.sni.com:443:54.149.143.27 to DNS cache
* Hostname test.sni.com was found in DNS cache
*   Trying 54.149.143.27... # <---- public IP of AWS ELB DNS
* TCP_NODELAY set
* Connected to test.sni.com (54.149.143.27) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* Cipher selection: ALL:!EXPORT:!EXPORT40:!EXPORT56:!aNULL:!LOW:!RC4:@STRENGTH
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/cert.pem
  CApath: none
* TLSv1.2 (OUT), TLS handshake, Client hello (1):
* TLSv1.2 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (IN), TLS handshake, Server key exchange (12):
* TLSv1.2 (IN), TLS handshake, Server finished (14):
* TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
* TLSv1.2 (OUT), TLS change cipher, Client hello (1):
* TLSv1.2 (OUT), TLS handshake, Finished (20):
* TLSv1.2 (IN), TLS change cipher, Client hello (1):
* TLSv1.2 (IN), TLS handshake, Finished (20):
* SSL connection using TLSv1.2 / ECDHE-RSA-CHACHA20-POLY1305
* ALPN, server accepted to use h2
* Server certificate:
*  subject: C=US; ST=Denial; L=Springfield; O=Dis; CN=*.sni.com # <---- using *.sni.com cert!
*  start date: Aug  7 13:53:39 2020 GMT
*  expire date: Aug 17 13:53:39 2021 GMT
*  issuer: C=US; ST=Denial; O=Dis; CN=*.sni.com
*  SSL certificate verify result: unable to get local issuer certificate (20), continuing anyway.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x7f855400ba00)
> GET /headers HTTP/2
> Host:test.sni.com # <----- 
> User-Agent: curl/7.54.0
> Accept: */*
> 
* Connection state changed (MAX_CONCURRENT_STREAMS updated)!
< HTTP/2 200  # <----- HTTP 200 returned
< server: istio-envoy
< date: Sat, 08 Aug 2020 07:59:07 GMT
< content-type: application/json
< content-length: 1631
< access-control-allow-origin: *
< access-control-allow-credentials: true
< x-envoy-upstream-service-time: 11
< 
{
  "headers": {
    "Accept": "*/*", 
    "Content-Length": "0", 
    "Host": "test.sni.com", 
    "User-Agent": "curl/7.54.0", 
    "X-B3-Sampled": "1", 
    "X-B3-Spanid": "acedc44ac22f6042", 
    "X-B3-Traceid": "efb45dc018cf5851acedc44ac22f6042", 
    "X-Envoy-Decorator-Operation": "httpbin.default.svc.cluster.local:80/headers", 
    "X-Envoy-Internal": "true", 
    "X-Envoy-Peer-Metadata": "ChoKCkNMVVNURVJfSUQSDBoKS3ViZXJuZXRlcwofCgxJTlNUQU5DRV9JUFMSDxoNMTkyLjE2OC42Ni43NAqWAgoGTEFCRUxTEosCKogCCh0KA2FwcBIWGhRpc3Rpby1pbmdyZXNzZ2F0ZXdheQoTCgVjaGFydBIKGghnYXRld2F5cwoUCghoZXJpdGFnZRIIGgZUaWxsZXIKGQoFaXN0aW8SEBoOaW5ncmVzc2dhdGV3YXkKIQoRcG9kLXRlbXBsYXRlLWhhc2gSDBoKNWQ4NjlmNWJiZgoSCgdyZWxlYXNlEgcaBWlzdGlvCjkKH3NlcnZpY2UuaXN0aW8uaW8vY2Fub25pY2FsLW5hbWUSFhoUaXN0aW8taW5ncmVzc2dhdGV3YXkKLwojc2VydmljZS5pc3Rpby5pby9jYW5vbmljYWwtcmV2aXNpb24SCBoGbGF0ZXN0ChoKB01FU0hfSUQSDxoNY2x1c3Rlci5sb2NhbAovCgROQU1FEicaJWlzdGlvLWluZ3Jlc3NnYXRld2F5LTVkODY5ZjViYmYtYnZweHMKGwoJTkFNRVNQQUNFEg4aDGlzdGlvLXN5c3RlbQpdCgVPV05FUhJUGlJrdWJlcm5ldGVzOi8vYXBpcy9hcHBzL3YxL25hbWVzcGFjZXMvaXN0aW8tc3lzdGVtL2RlcGxveW1lbnRzL2lzdGlvLWluZ3Jlc3NnYXRld2F5CqcBChFQTEFURk9STV9NRVRBREFUQRKRASqOAQogCg5hd3NfYWNjb3VudF9pZBIOGgwxNjQ5MjU1OTYzMTUKJQoVYXdzX2F2YWlsYWJpbGl0eV96b25lEgwaCnVzLXdlc3QtMmQKKAoPYXdzX2luc3RhbmNlX2lkEhUaE2ktMDQ3Yzc0MTQ3NjZhZjIwNmUKGQoKYXdzX3JlZ2lvbhILGgl1cy13ZXN0LTIKOQoPU0VSVklDRV9BQ0NPVU5UEiYaJGlzdGlvLWluZ3Jlc3NnYXRld2F5LXNlcnZpY2UtYWNjb3VudAonCg1XT1JLTE9BRF9OQU1FEhYaFGlzdGlvLWluZ3Jlc3NnYXRld2F5", 
    "X-Envoy-Peer-Metadata-Id": "router~192.168.66.74~istio-ingressgateway-5d869f5bbf-bvpxs.istio-system~istio-system.svc.cluster.local"
  }
}
* Connection #0 to host test.sni.com left intact
```


__うまくいかない例__ 
```sh
# not working: "sni.com"は"*.sni.com"に含まれないため
curl -v \
  --resolve "sni.com:$SECURE_INGRESS_PORT:$(host $(echo $INGRESS_HOST) | tail -1 | awk '{ print $4 }')" \
  "https://sni.com:$SECURE_INGRESS_PORT/headers" -k

# not working:　$INGRESS_HOST がpublic IPでない場合、DNSをIPにResolveするため $(host $(echo $INGRESS_HOST) | tail -1 | awk '{ print $4 }')をする必要がある
curl -v \
  -HHost:test.sni.com \
  --cacert istio-elb.sni.com.cert.pem \
  --resolve "test.sni.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
  "https://test.sni.com:$SECURE_INGRESS_PORT/headers"
```




# 7.3 Istio Service Mesh内でMutual TLSが有効化されているのを確認する
Ref:
- https://istio.io/latest/docs/tasks/security/authentication/authn-policy/#auto-mutual-tls


![alt text](../imgs/istio_mesh_mtls.png "")


> all traffic between workloads with proxies uses mutual TLS, without you doing anything


もしmutual TLSが有効化されている場合, Envoy proxyが `X-Forwarded-Client-Cert` をheaderのリクエストに追加します。

`curl` から`httpbin`にCurlしてみる
```sh
# curl podのYAMLを生成
kubectl run curl \
    --restart Never \
    --image curlimages/curl \
    --dry-run -o yaml \
    -- /bin/sh -c "sleep infinity" > pod_curl.yaml

# アプライ
kubectl apply -f pod_curl.yaml


# curl containerのShellに接続し, httpbin serviceにCurlして、"X-Forwarded-Client-Cert"がリスポンスにあるかGrep
kubectl exec -it curl sh
curl httpbin/headers | grep -I X-Forwarded-Client-Cert

# アウトプット 
"X-Forwarded-Client-Cert": "By=spiffe://cluster.local/ns/default/sa/default;Hash=d251b241c9b4f51b5d596e7d32e46916e7dc7d3b087b633412e6e2eaea738d5f;Subject=\"\";URI=spiffe://cluster.local/ns/default/sa/default"

# もう一度httpbinにCurl
curl httpbin/headers

# アウトプット
{
  "headers": {
    "Accept": "*/*", 
    "Content-Length": "0", 
    "Host": "httpbin", 
    "User-Agent": "curl/7.71.1-DEV", 
    "X-B3-Parentspanid": "0a649da2f5a4b574", 
    "X-B3-Sampled": "1", 
    "X-B3-Spanid": "66c68ec9f592c922", 
    "X-B3-Traceid": "2259a9fb0ad227650a649da2f5a4b574", 
    "X-Envoy-Attempt-Count": "1", 
    "X-Forwarded-Client-Cert": "By=spiffe://cluster.local/ns/default/sa/default;Hash=d251b241c9b4f51b5d596e7d32e46916e7dc7d3b087b633412e6e2eaea738d5f;Subject=\"\";URI=spiffe://cluster.local/ns/default/sa/default" # <----- Isito sidecar proxyがこのHeaderをInjectしているので、Mutual TLSが有効化されているのが確認できる
  }
```



# 7.4 Mutual-TLSのSTRICTモードをMesh全体(全てのnamespaces)に有効化する
Ref:
- https://istio.io/latest/docs/tasks/security/authentication/authn-policy/#globally-enabling-istio-mutual-tls-in-strict-mode

> While Istio automatically upgrades all traffic between the proxies and the workloads to mutual TLS between, __workloads can still receive plain text traffic__. To prevent non-mutual TLS for the whole mesh, set a mesh-wide peer authentication policy to set mutual TLS mode to STRICT.


## STRICT MODEの前

`curl` podからnon-mutual TLS（Plain　HTTP）のリクエストを`httpbin` podへ送れる
```sh
# まずは新しいnamespaceを作成し、istio sidecar injectionを有効化しない（Sidecar Envoy ProxyがInjectされないので、全てHTTPになる）
kubectl create ns non-istio

# curl podをnon-istio namespaceに作るため、YAMLを生成
kubectl run curl \
    --restart Never \
    --image curlimages/curl \
    -n non-istio \
    --dry-run -o yaml \
    -- /bin/sh -c "sleep infinity" > pod_curl_non_istio.yaml

# アプライ
kubectl apply -f pod_curl_non_istio.yaml

kubectl get pod -n non-istio

# アウトプットで、1つcontainerしかcurl podにないのがわかる（つまり、istio sidecar envoy proxy containerがない）
NAME   READY   STATUS    RESTARTS   AGE
curl   1/1     Running   0          12s


# default namespaceのhttpbinに、non-istio namespaceのcurl coontainerからCurlする
kubectl exec -it curl -n non-istio sh
curl httpbin.default/headers | grep -I X-Forwarded-Client-Cert

# ”X-Forwarded-Client-Cert”の文字検索にひっかからないので、何もReturnされない

# ただ、 default namespaceのistio-enabled httpbin podに接続はできる
curl httpbin.default/headers -I

# アウトプットでHTTP 200が返ってくる
HTTP/1.1 200 OK
server: istio-envoy
date: Wed, 05 Aug 2020 13:34:30 GMT
content-type: application/json
content-length: 264
access-control-allow-origin: *
access-control-allow-credentials: true
x-envoy-upstream-service-time: 2
x-envoy-decorator-operation: httpbin.default.svc.cluster.local:80/*
```

## STRICT MODEの後

[peer_authentication_strict_mutual_tls_global.yaml](peer_authentication_strict_mutual_tls_global.yaml),
```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system

spec:
  mtls:
    mode: STRICT # Mesh内のworkloadsが、TLSコネクションのみ受け入れるように設定
```

アプライ
```sh
kubectl apply -f peer_authentication_strict_mutual_tls_global.yaml
```

non-mutual TLS traffic を`curl` pod から`httpbin` podに送ってみる
```sh
# default namespaceのhttpbinに non-istio namespace内のcurlコンテナからCurlする
kubectl exec -it curl -n non-istio sh
curl httpbin.default/headers -v

# アウトプットでコネクションが失敗したのがわかる
*   Trying 10.100.88.82:80...
* Connected to httpbin.default (10.100.88.82) port 80 (#0)
> GET /headers HTTP/1.1
> Host: httpbin.default
> User-Agent: curl/7.71.1-DEV
> Accept: */*
> 
* Recv failure: Connection reset by peer
* Closing connection 0
curl: (56) Recv failure: Connection reset by peer
```



# 7.5 Mutual-TLSのSTRICTモードをMesh内のNamespace限定で有効化する
Ref:
- https://istio.io/latest/docs/tasks/security/authentication/authn-policy/#enable-mutual-tls-per-workload


![alt text](../imgs/istio_peerauthentication_strict_mtls.png "")


まずは前のセクションで設定したGlobalの`PeerAuthentication`の設定を削除
```
kubectl delete pa default -n istio-system
```


[peer_authentication_strict_mutual_tls_default_ns.yaml](peer_authentication_strict_mutual_tls_default_ns.yaml)で、 STRICT mutual TLS を`default` namespaceのみ適応する
```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: default # このNamespaceのIncoming Trafficに対してルールを適応
spec:
  mtls:
    mode: STRICT 
```

アプライ
```sh
kubectl apply -f peer_authentication_strict_mutual_tls_default_ns.yaml
```

`non-istio` namespaceから`default`namespace内の`httpbin`へのnon-mutual TLSリクエストがブロックされているのを確認する
```sh
# default namespace内のhttpbinに、non-istio namespaceのcurlコンテナからCurlする
kubectl exec -it curl -n non-istio sh
curl httpbin.default/headers -v

# アウトプットで、ブロックされているのが確認できる
*   Trying 10.100.88.82:80...
* Connected to httpbin.default (10.100.88.82) port 80 (#0)
> GET /headers HTTP/1.1
> Host: httpbin.default
> User-Agent: curl/7.71.1-DEV
> Accept: */*
> 
* Recv failure: Connection reset by peer
* Closing connection 0
curl: (56) Recv failure: Connection reset by peer
```


次に、新しい`istio-enabled` namespaceを作成し、`httpbin`Podを作成
```sh
kubectl create ns istio-enabled

# istioを有効化
kubectl label namespace istio-enabled istio-injection=enabled
```

`non-istio` namespaceから、`istio-enabled`namespace内の`httpbin`へのnon-mutual TLSリクエストが  __ブロックされていない__ のを確認する
```sh
# istio-enabled namespace内にhttpbin podを作成（Defaultのnamespace以外はSTRICT mutual TLSは有効化されていない）
kubectl run httpbin \
    --restart Never \
    -n istio-enabled \
    --image docker.io/kennethreitz/httpbin

# httpbin pod をクラスター内にServiceで公開
kubectl expose pod httpbin --port 80 -n istio-enabled

kubectl exec -it curl -n non-istio sh
curl httpbin.istio-enabled/headers -v

# アウトプットで、istio-enabled namespace内のhttpbin podへはnon-mutual TLSリクエストがブロックされていないのが確認できる
*   Trying 10.100.32.14:80...
* Connected to httpbin.istio-enabled (10.100.32.14) port 80 (#0)
> GET /headers HTTP/1.1
> Host: httpbin.istio-enabled
> User-Agent: curl/7.71.1-DEV
> Accept: */*
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK # <----- http 200
< server: istio-envoy
< date: Wed, 05 Aug 2020 13:58:16 GMT
< content-type: application/json
< content-length: 270
< access-control-allow-origin: *
< access-control-allow-credentials: true
< x-envoy-upstream-service-time: 3 
< x-envoy-decorator-operation: httpbin.istio-enabled.svc.cluster.local:80/*
< 
{
  "headers": {
    "Accept": "*/*", 
    "Content-Length": "0", 
    "Host": "httpbin.istio-enabled", 
    "User-Agent": "curl/7.71.1-DEV", 
    "X-B3-Sampled": "1", 
    "X-B3-Spanid": "c5561cfb1526907d", 
    "X-B3-Traceid": "9bc6798b367798b7c5561cfb1526907d" # <----- X-Forwarded-Client-Certが見つからないので、non-mutual TLS plain requestが送られたのがわかる
  }
}
* Connection #0 to host httpbin.istio-enabled left intact
```



# 7.6 Mutual-TLSのSTRICTモードをMesh内のNamespaceのWorkload限定で有効化する
Ref:
- https://istio.io/latest/docs/tasks/security/authentication/authn-policy/#policy-precedence

> A workload-specific peer authentication policy takes precedence over a namespace-wide policy.


## Workload限定のSTRICT MODE前

Non-mutual TLS trafficを `curl` podからDefaultのNamespace内の`httpbin` podへ送れないのを確認
```sh
# default namespace内のhttpbinに、non-istio namespace内のcurlコンテナからCurlする
kubectl exec -it curl -n non-istio sh

# STRICT mutual TLSにより失敗する
curl httpbin.default/headers -I

# default namespace内のProductpageへも失敗する
curl productpage.default:9080 -I

# アウトプット
curl: (56) Recv failure: Connection reset by peer


# しかし、default namespace以外なら成功する
curl httpbin.istio-enabled/headers -I
```

## Workload限定のSTRICT MODE後

まずは前セクションで設定した`PeerAuthentication`を削除する
```
kubectl delete pa default -n default
```

[peer_authentication_strict_mutual_tls_httpbin.yaml](peer_authentication_strict_mutual_tls_httpbin.yaml)で,　STRICT mutual TLSを`default` namespace内の`app: httpbin`のラベルがあるPodのみに設定する
```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: default # namespace-wide policy
spec:
  selector:
    matchLabels:
      run: httpbin # <---- このpod labelに当てはまるもののみ設定
  mtls:
    mode: STRICT
```

また、Destination Ruleを作る必要があるので、
[destinationrule_strict_mutual_tls_httpbin.yaml](destinationrule_strict_mutual_tls_httpbin.yaml)を作成
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: httpbin
spec:
  host: httpbin.default # <--- outgoing requestのホストをして
  trafficPolicy:
    tls: 
      mode: ISTIO_MUTUAL # <---- strict mutual TLSをここでも指定
```

アプライ
```
kubectl apply -f destinationrule_strict_mutual_tls_httpbin.yaml 
kubectl apply -f peer_authentication_strict_mutual_tls_httpbin.yaml
```

Non-mutual TLS trafficを`curl` podからDefaultのNamespace内の`httpbin` podへ送れないのが、
`productpage`へは送れるのを確認
```sh
# default namespace内のhttpbinに、non-istio namespace内のcurlコンテナからCurlする
kubectl exec -it curl -n non-istio sh

# STRICT mutual TLSにより失敗する
curl httpbin.default/headers -I

# アウトプット
curl: (56) Recv failure: Connection reset by peer

# しかし`productpage`へは送れる
curl productpage.default:9080 -I

# アウトプット
HTTP/1.1 200 OK
content-type: text/html; charset=utf-8
content-length: 1683
server: istio-envoy
date: Wed, 05 Aug 2020 14:32:25 GMT
x-envoy-upstream-service-time: 11
x-envoy-decorator-operation: productpage.default.svc.cluster.local:9080/*


# もちろんdefault namespace以外も成功する
curl httpbin.istio-enabled/headers -I
```



# 7.7 HTTPからHTTPSへのRedirectを設定する
Ref: https://istio.io/docs/reference/config/networking/gateway/

[gateway_https_sni_https_redirect.yaml](gateway_https_sni_https_redirect.yaml)で, port 80からport 443へRidirect:
```sh
  servers: 
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts: # host in http header
    - "a1abfd566d68643928e9ee352211f89a-1032923527.us-east-1.elb.amazonaws.com"
    tls:
      httpsRedirect: true # 301 redirectを最初にRequestに対しReturnし、その後httpsへRedirect
```

アプライ
```
kubectl apply -f gateway_https_sni_https_redirect.yaml
```

HTTPリクエストを送って、テストする
```sh
curl -v \
    http://$(echo $(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')/headers)

# HTTP 301がReturnされるはず

# 今度は、-L（または--Location)を使って、RedirectされたLocationをFollowするように指示し、-k（--insecure）もPassする（HTTPSのTLS　CertがSelf-signed CertでInsecureなため）
curl -v \
    http://$(echo $(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')/headers) -L -k

# アウトプット 
*   Trying 54.149.45.218...
* TCP_NODELAY set
* Connected to aa763752bdc8e4907bcd5746efe95b9c-1399209693.us-west-2.elb.amazonaws.com (54.149.45.218) port 80 (#0)
> GET /headers HTTP/1.1
> Host: aa763752bdc8e4907bcd5746efe95b9c-1399209693.us-west-2.elb.amazonaws.com
> User-Agent: curl/7.54.0
> Accept: */*
> 
< HTTP/1.1 301 Moved Permanently # <------- １回目のHTTP requestに対するResponseは３０１
< location: https://aa763752bdc8e4907bcd5746efe95b9c-1399209693.us-west-2.elb.amazonaws.com/headers
< date: Thu, 20 Aug 2020 20:19:46 GMT
< server: istio-envoy
< content-length: 0
< 
* Connection #0 to host aa763752bdc8e4907bcd5746efe95b9c-1399209693.us-west-2.elb.amazonaws.com left intact
* Issue another request to this URL: 'https://aa763752bdc8e4907bcd5746efe95b9c-1399209693.us-west-2.elb.amazonaws.com/headers'
*   Trying 54.149.45.218...　# <------- ２回目のRequest
* TCP_NODELAY set
* Connected to aa763752bdc8e4907bcd5746efe95b9c-1399209693.us-west-2.elb.amazonaws.com (54.149.45.218) port 443 (#1)
* ALPN, offering h2
* ALPN, offering http/1.1
* Cipher selection: ALL:!EXPORT:!EXPORT40:!EXPORT56:!aNULL:!LOW:!RC4:@STRENGTH
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/cert.pem
  CApath: none
* TLSv1.2 (OUT), TLS handshake, Client hello (1):
* TLSv1.2 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (IN), TLS handshake, Server key exchange (12):
* TLSv1.2 (IN), TLS handshake, Server finished (14):
* TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
* TLSv1.2 (OUT), TLS change cipher, Client hello (1):
* TLSv1.2 (OUT), TLS handshake, Finished (20):
* TLSv1.2 (IN), TLS change cipher, Client hello (1):
* TLSv1.2 (IN), TLS handshake, Finished (20):
* SSL connection using TLSv1.2 / ECDHE-RSA-CHACHA20-POLY1305
* ALPN, server accepted to use h2
* Server certificate:
*  subject: CN=*.elb.amazonaws.com
*  start date: Aug 20 17:51:18 2020 GMT
*  expire date: Aug 20 17:51:18 2021 GMT
*  issuer: CN=*.elb.amazonaws.com
*  SSL certificate verify result: self signed certificate (18), continuing anyway.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x7fdac280ba00)
> GET /headers HTTP/2
> Host: aa763752bdc8e4907bcd5746efe95b9c-1399209693.us-west-2.elb.amazonaws.com
> User-Agent: curl/7.54.0
> Accept: */*
> 
* Connection state changed (MAX_CONCURRENT_STREAMS updated)!
< HTTP/2 200 # <----- HTTP 200が返ってきた
< server: istio-envoy
< date: Thu, 20 Aug 2020 20:19:47 GMT
< content-type: application/json
< content-length: 1690
< access-control-allow-origin: *
< access-control-allow-credentials: true
< x-envoy-upstream-service-time: 5
< 
{
  "headers": {
    "Accept": "*/*", 
    "Content-Length": "0", 
    "Host": "aa763752bdc8e4907bcd5746efe95b9c-1399209693.us-west-2.elb.amazonaws.com", 
    "User-Agent": "curl/7.54.0", 
    "X-B3-Sampled": "1", 
    "X-B3-Spanid": "48cc131fc275de57", 
    "X-B3-Traceid": "c7bdb23dbb04d5b848cc131fc275de57", 
    "X-Envoy-Decorator-Operation": "httpbin.default.svc.cluster.local:80/headers", 
    "X-Envoy-Internal": "true", 
    "X-Envoy-Peer-Metadata": "ChoKCkNMVVNURVJfSUQSDBoKS3ViZXJuZXRlcwofCgxJTlNUQU5DRV9JUFMSDxoNMTkyLjE2OC4xMy4zNwqWAgoGTEFCRUxTEosCKogCCh0KA2FwcBIWGhRpc3Rpby1pbmdyZXNzZ2F0ZXdheQoTCgVjaGFydBIKGghnYXRld2F5cwoUCghoZXJpdGFnZRIIGgZUaWxsZXIKGQoFaXN0aW8SEBoOaW5ncmVzc2dhdGV3YXkKIQoRcG9kLXRlbXBsYXRlLWhhc2gSDBoKODQ5Yzc2ZDk1OQoSCgdyZWxlYXNlEgcaBWlzdGlvCjkKH3NlcnZpY2UuaXN0aW8uaW8vY2Fub25pY2FsLW5hbWUSFhoUaXN0aW8taW5ncmVzc2dhdGV3YXkKLwojc2VydmljZS5pc3Rpby5pby9jYW5vbmljYWwtcmV2aXNpb24SCBoGbGF0ZXN0ChoKB01FU0hfSUQSDxoNY2x1c3Rlci5sb2NhbAovCgROQU1FEicaJWlzdGlvLWluZ3Jlc3NnYXRld2F5LTg0OWM3NmQ5NTktcDVkOWIKGwoJTkFNRVNQQUNFEg4aDGlzdGlvLXN5c3RlbQpdCgVPV05FUhJUGlJrdWJlcm5ldGVzOi8vYXBpcy9hcHBzL3YxL25hbWVzcGFjZXMvaXN0aW8tc3lzdGVtL2RlcGxveW1lbnRzL2lzdGlvLWluZ3Jlc3NnYXRld2F5CqcBChFQTEFURk9STV9NRVRBREFUQRKRASqOAQogCg5hd3NfYWNjb3VudF9pZBIOGgwxNjQ5MjU1OTYzMTUKJQoVYXdzX2F2YWlsYWJpbGl0eV96b25lEgwaCnVzLXdlc3QtMmQKKAoPYXdzX2luc3RhbmNlX2lkEhUaE2ktMDVhZDk3ZTI0NzllZmRkNGUKGQoKYXdzX3JlZ2lvbhILGgl1cy13ZXN0LTIKOQoPU0VSVklDRV9BQ0NPVU5UEiYaJGlzdGlvLWluZ3Jlc3NnYXRld2F5LXNlcnZpY2UtYWNjb3VudAonCg1XT1JLTE9BRF9OQU1FEhYaFGlzdGlvLWluZ3Jlc3NnYXRld2F5", 
    "X-Envoy-Peer-Metadata-Id": "router~192.168.13.37~istio-ingressgateway-849c76d959-p5d9b.istio-system~istio-system.svc.cluster.local"
  }
}
```

