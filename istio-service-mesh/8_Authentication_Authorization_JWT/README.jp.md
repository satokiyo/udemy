# 8 JWT(Json Web Token)を使って認証（Authentication）と認可（Authorization）を設定

# 8.1 RequestAuthenticationとAuthorizationPolicyでJWT Tokenを使って、End-Userの認証・認可を有効化 
Ref: 
- https://istio.io/latest/docs/tasks/security/authentication/authn-policy/#end-user-authentication
- https://istio.io/latest/docs/tasks/security/authentication/authn-policy/#require-a-valid-token
- https://istio.io/latest/docs/reference/config/security/authorization-policy/#AuthorizationPolicy
- https://istio.io/latest/docs/tasks/security/authorization/authz-jwt/


![alt text](../imgs/istio_requestauthentication_authorizationpolicy_jwt.png "")


## Step 1: Istio Request AuthenticationとAuthorization policyを作成

[request_authentication.yaml](request_authentication.yaml)の  __request authentication policy__ で、ingress gatewayにJWTを必須化するよう設定
```yaml
apiVersion: security.istio.io/v1beta1
kind: RequestAuthentication
metadata:
  name: jwt-example
  namespace: istio-system # IstioのRootネームスペースに適用
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  jwtRules: # <-----　ここでJWTを必須化
  - issuer: testing@secure.istio.io
    jwksUri: https://raw.githubusercontent.com/istio/istio/release-1.6/security/tools/jwt/samples/jwks.json
```

[authorization_policy.yaml](authorization_policy.yaml)で, ValidなJWTがないHTTPリクエストは拒否するよう設定 
```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: httpbin
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  action: DENY # requestsを拒否する
  rules:
  - from:
    - source:
        notRequestPrincipals: ["*"] # <---- HTTP request headerにprincipalsがない場合 (validではないJWTの場合Principalsがない) 
```

アプライ
```
kubectl apply -f request_authentication.yaml
kubectl apply -f authorization_policy.yaml
```

## JWTの認証・認可をテスト

`/headers` をJWTなしでアクセスすると`HTTP/1.1 403 Forbidden`エラーが返ってくる
```sh
curl $INGRESS_HOST/headers -v

# アウトプット
*   Trying 34.214.199.244...
* TCP_NODELAY set
* Connected to a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com (34.214.199.244) port 80 (#0)
> GET /headers HTTP/1.1
> Host: a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com
> User-Agent: curl/7.54.0
> Accept: */*
> 
< HTTP/1.1 403 Forbidden # <---- エラー
< content-length: 19
< content-type: text/plain
< date: Sat, 08 Aug 2020 09:23:47 GMT
< server: istio-envoy
< 
* Connection #0 to host a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com left intact
```

今度は __INVALID__ なJWT`deadbeef`を`Authorization: Bearer` headerでパスしてみると,　`HTTP 401 Unauthorized`エラーが返ってくる
```sh
curl --header "Authorization: Bearer deadbeef" $INGRESS_HOST/headers -v

# アウトプット
*   Trying 54.149.143.27...
* TCP_NODELAY set
* Connected to a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com (54.149.143.27) port 80 (#0)
> GET /headers HTTP/1.1
> Host: a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com
> User-Agent: curl/7.54.0
> Accept: */*
> Authorization: Bearer deadbeef
> 
< HTTP/1.1 401 Unauthorized　# <ーーーーエラー
< content-length: 50
< content-type: text/plain
< date: Sat, 08 Aug 2020 09:17:49 GMT
< server: istio-envoy
< 
* Connection #0 to host a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com left intact
Jwt is not in the form of Header.Payload.Signature
```

最後に __VALID__ なJWTトークンを`Authorization: Bearer` headerでPassすると, `200`で成功する
```sh
# まずvalid JWT トークンをShellの変数に保存
TOKEN=$(curl https://raw.githubusercontent.com/istio/istio/release-1.6/security/tools/jwt/samples/demo.jwt -s)
echo $TOKEN

curl --header "Authorization: Bearer $TOKEN" $INGRESS_HOST/headers -v -L -k

# successful アウトプット
*   Trying 34.214.199.244...
* TCP_NODELAY set
* Connected to a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com (34.214.199.244) port 80 (#0)
> GET /headers HTTP/1.1
> Host: a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com
> User-Agent: curl/7.54.0
> Accept: */*
> Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6IkRIRmJwb0lVcXJZOHQyenBBMnFYZkNtcjVWTzVaRXI0UnpIVV8tZW52dlEiLCJ0eXAiOiJKV1QifQ.eyJleHAiOjQ2ODU5ODk3MDAsImZvbyI6ImJhciIsImlhdCI6MTUzMjM4OTcwMCwiaXNzIjoidGVzdGluZ0BzZWN1cmUuaXN0aW8uaW8iLCJzdWIiOiJ0ZXN0aW5nQHNlY3VyZS5pc3Rpby5pbyJ9.CfNnxWP2tcnR9q0vxyxweaF3ovQYHYZl82hAUsn21bwQd9zP7c-LS9qd_vpdLG4Tn1A15NxfCjp5f7QNBUo-KC9PJqYpgGbaXhaGx7bEdFWjcwv3nZzvc7M__ZpaCERdwU7igUmJqYGBYQ51vr2njU9ZimyKkfDe3axcyiBZde7G6dabliUosJvvKOPcKIWPccCgefSj_GNfwIip3-SsFdlR7BtbVUcqR-yv-XOxJ3Uc1MI0tz3uMiiZcyPV7sNCU4KRnemRIMHVOfuvHsU60_GhGbiSFzgPTAa9WTltbnarTbxudb_YEOx12JiwYToeX0DCPb43W1tzIBxgm8NxUg # <----- JWT token in header
> 
< HTTP/1.1 200 OK
< server: istio-envoy
< date: Sat, 08 Aug 2020 09:20:13 GMT
< content-type: application/json
< content-length: 1689
< access-control-allow-origin: *
< access-control-allow-credentials: true
< x-envoy-upstream-service-time: 4
```


# 8.2 指定したHTTP pathに対して、JWT Tokenによる認証・認可を有効化する


![alt text](../imgs/istio_requestauthentication_authorizationpolicy_jwt_path.png "")


下記のYAMLでは、`/headers`のPATHのみJWTによる認証を有効化します

In [authorization_policy_httpbin_path.yaml](authorization_policy_httpbin_path.yaml),
```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: allow-path
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  action: DENY 
  rules:
  - from:
    - source:
        notRequestPrincipals: ["*"] 
    to:
      - operation:
          paths: ["/headers"] # <---- この/headers ではJWT無しの場合拒否
```

アプライ
```sh
# まずは前セクションで作った authorization policyを削除
kubectl delete authorizationpolicy frontend-ingress -n istio-system

kubectl apply -f authorization_policy_httpbin_path.yaml
```

## /headersに JWT無しでリクエストを送るとエラーになるのをテスト

```sh
curl $INGRESS_HOST/headers -v

# アウトプットでエラーが返ってくる
*   Trying 54.149.143.27...
* TCP_NODELAY set
* Connected to a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com (54.149.143.27) port 80 (#0)
> GET /headers HTTP/1.1
> Host: a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com
> User-Agent: curl/7.54.0
> Accept: */*
> 
< HTTP/1.1 403 Forbidden # <----- 認可失敗
< content-length: 19
< content-type: text/plain
< date: Sat, 08 Aug 2020 09:41:09 GMT
< server: istio-envoy
< 
* Connection #0 to host a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com left intact
RBAC: access denied # <----- 認可失敗
```

JWTをPassすると200が返ってくる
```sh
curl --header "Authorization: Bearer $TOKEN" $INGRESS_HOST/headers -v -L -k

# successful アウトプット
*   Trying 54.149.143.27...
* TCP_NODELAY set
* Connected to a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com (54.149.143.27) port 80 (#0)
> GET /headers HTTP/1.1
> Host: a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com
> User-Agent: curl/7.54.0
> Accept: */*
> Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6IkRIRmJwb0lVcXJZOHQyenBBMnFYZkNtcjVWTzVaRXI0UnpIVV8tZW52dlEiLCJ0eXAiOiJKV1QifQ.eyJleHAiOjQ2ODU5ODk3MDAsImZvbyI6ImJhciIsImlhdCI6MTUzMjM4OTcwMCwiaXNzIjoidGVzdGluZ0BzZWN1cmUuaXN0aW8uaW8iLCJzdWIiOiJ0ZXN0aW5nQHNlY3VyZS5pc3Rpby5pbyJ9.CfNnxWP2tcnR9q0vxyxweaF3ovQYHYZl82hAUsn21bwQd9zP7c-LS9qd_vpdLG4Tn1A15NxfCjp5f7QNBUo-KC9PJqYpgGbaXhaGx7bEdFWjcwv3nZzvc7M__ZpaCERdwU7igUmJqYGBYQ51vr2njU9ZimyKkfDe3axcyiBZde7G6dabliUosJvvKOPcKIWPccCgefSj_GNfwIip3-SsFdlR7BtbVUcqR-yv-XOxJ3Uc1MI0tz3uMiiZcyPV7sNCU4KRnemRIMHVOfuvHsU60_GhGbiSFzgPTAa9WTltbnarTbxudb_YEOx12JiwYToeX0DCPb43W1tzIBxgm8NxUg
> 
< HTTP/1.1 200 OK　# <---- 成功
< server: istio-envoy
< date: Sat, 08 Aug 2020 09:40:57 GMT
< content-type: application/json
< content-length: 1689
< access-control-allow-origin: *
< access-control-allow-credentials: true
< x-envoy-upstream-service-time: 3
```

## /ipにJWT無しのリクエストを送っても失敗しないのをテスト
```sh
curl $INGRESS_HOST/ip -v -k -L

# successful アウトプット
*   Trying 54.149.143.27...
* TCP_NODELAY set
* Connected to a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com (54.149.143.27) port 80 (#0)
> GET /ip HTTP/1.1
> Host: a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com
> User-Agent: curl/7.54.0
> Accept: */*
> 
< HTTP/1.1 200 OK # <---- 成功
< server: istio-envoy
< date: Sat, 08 Aug 2020 09:41:17 GMT
< content-type: application/json
< content-length: 32
< access-control-allow-origin: *
< access-control-allow-credentials: true
< x-envoy-upstream-service-time: 3
< 
{
  "origin": "192.168.69.89"
}
```


# 8.3 指定したHTTP pathとHOST(ドメイン)に対して、JWT Tokenによる認証・認可を有効化する

下記のYAMLでは、`/headers`だけでなく、`*.sni.com`の場合にも、JWTによる認証が有効化されます。

[authorization_policy_httpbin_path_host.yaml](authorization_policy_httpbin_path_host.yaml),
```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: allow-path-host
  namespace: istio-system 
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  action: DENY 
  rules:
  - from:
    - source:
        notRequestPrincipals: ["*"] 
    to:
    - operation:
        # ANDの条件 (i.e. test.sni.com/headers)
        paths: ["/headers"] # <---- deny if invalid JWT token for /headers
        hosts: ["test.sni.com"] 
    # ORの条件 (i.e.  */headers もしくわ test.sni.com/*)
    # - operation:
    #     hosts: ["test.sni.com"] 
```

アプライ
```sh
# まずは前セクションで作った authorization policyを削除
kubectl delete -f authorization_policy_httpbin_path.yaml

kubectl apply -f authorization_policy_httpbin_path_host.yaml
```


## "*.sni.com/headers"へのリクエストが、JWT無しだとエラーになるのをテスト

```sh
curl -v \
  --resolve "test.sni.com:$SECURE_INGRESS_PORT:$(host $(echo $INGRESS_HOST) | tail -1 | awk '{ print $4 }')" \
  "https://test.sni.com:$SECURE_INGRESS_PORT/headers" -k

# エラーのアウトプット
* Added test.sni.com:443:54.149.143.27 to DNS cache
* Hostname test.sni.com was found in DNS cache
*   Trying 54.149.143.27...
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
*  subject: CN=*.sni.com # <----- SNIのおかげで、正しいTLS certが使われている
*  start date: Aug  7 08:12:52 2020 GMT
*  expire date: Aug  7 08:12:52 2021 GMT
*  issuer: CN=*.sni.com
*  SSL certificate verify result: self signed certificate (18), continuing anyway.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x7fdfc600ba00)
> GET /headers HTTP/2
> Host: test.sni.com # <------ hostは *.sni.com
> User-Agent: curl/7.54.0
> Accept: */*
> 
* Connection state changed (MAX_CONCURRENT_STREAMS updated)!
< HTTP/2 403 
< content-length: 19
< content-type: text/plain
< date: Sat, 08 Aug 2020 10:38:35 GMT
< server: istio-envoy
< 
* Connection #0 to host test.sni.com left intact
RBAC: access denie  # <----- 認可失敗
```


## "*.sni.com/headers"へのリクエストが、JWT有りだと成功するのをテスト
```sh
# --header "Authorization: Bearer $TOKEN"を指定
curl -v \
  --resolve "test.sni.com:$SECURE_INGRESS_PORT:$(host $(echo $INGRESS_HOST) | tail -1 | awk '{ print $4 }')" \
  --header "Authorization: Bearer $TOKEN" \
  "https://test.sni.com:$SECURE_INGRESS_PORT/headers" -k


# successful アウトプット
* Added test.sni.com:443:34.214.199.244 to DNS cache
* Hostname test.sni.com was found in DNS cache
*   Trying 34.214.199.244...
* TCP_NODELAY set
* Connected to test.sni.com (34.214.199.244) port 443 (#0)
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
*  subject: CN=*.sni.com # <----- SNIのおかげで、正しいTLS certが使われている
*  start date: Aug  7 08:12:52 2020 GMT
*  expire date: Aug  7 08:12:52 2021 GMT
*  issuer: CN=*.sni.com
*  SSL certificate verify result: self signed certificate (18), continuing anyway.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x7fe88400ba00)
> GET /headers HTTP/2
> Host: test.sni.com # <------ hostは *.sni.com
> User-Agent: curl/7.54.0
> Accept: */*
> Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6IkRIRmJwb0lVcXJZOHQyenBBMnFYZkNtcjVWTzVaRXI0UnpIVV8tZW52dlEiLCJ0eXAiOiJKV1QifQ.eyJleHAiOjQ2ODU5ODk3MDAsImZvbyI6ImJhciIsImlhdCI6MTUzMjM4OTcwMCwiaXNzIjoidGVzdGluZ0BzZWN1cmUuaXN0aW8uaW8iLCJzdWIiOiJ0ZXN0aW5nQHNlY3VyZS5pc3Rpby5pbyJ9.CfNnxWP2tcnR9q0vxyxweaF3ovQYHYZl82hAUsn21bwQd9zP7c-LS9qd_vpdLG4Tn1A15NxfCjp5f7QNBUo-KC9PJqYpgGbaXhaGx7bEdFWjcwv3nZzvc7M__ZpaCERdwU7igUmJqYGBYQ51vr2njU9ZimyKkfDe3axcyiBZde7G6dabliUosJvvKOPcKIWPccCgefSj_GNfwIip3-SsFdlR7BtbVUcqR-yv-XOxJ3Uc1MI0tz3uMiiZcyPV7sNCU4KRnemRIMHVOfuvHsU60_GhGbiSFzgPTAa9WTltbnarTbxudb_YEOx12JiwYToeX0DCPb43W1tzIBxgm8NxUg
> 
* Connection state changed (MAX_CONCURRENT_STREAMS updated)!
< HTTP/2 200  # <----- HTTP 200
< server: istio-envoy
< date: Sat, 08 Aug 2020 10:43:49 GMT
< content-type: application/json
< content-length: 1631
< access-control-allow-origin: *
< access-control-allow-credentials: true
< x-envoy-upstream-service-time: 3
```


## "*.elb.amazonaws.com/headers"へのリクエストが、JWT無しでも成功するのをテスト
```sh
# 今回は"*.elb.amazonaws.com"にリクエストを送るので、--resolve for "*.sni.com"を指定する必要無し
curl https://$INGRESS_HOST/headers -v -k  

# successful アウトプット
*Trying 54.149.143.27...* TCP_NODELAY set
* Connected to a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com (54.149.143.27) port 443 (#0)
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
*  subject: CN=*.elb.amazonaws.com # <------ host is NOT *.sni.com
*  start date: Aug  5 11:00:46 2020 GMT
*  expire date: Aug  5 11:00:46 2021 GMT
*  issuer: CN=*.elb.amazonaws.com
*  SSL certificate verify result: self signed certificate (18), continuing anyway.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x7ff33f80ba00)
> GET /headers HTTP/2
> Host: a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com
> User-Agent: curl/7.54.0
> Accept: */*
> 
* Connection state changed (MAX_CONCURRENT_STREAMS updated)!
< HTTP/2 200  # <------ HTTP 200
< server: istio-envoy
< date: Sat, 08 Aug 2020 10:46:01 GMT
< content-type: application/json
< content-length: 1689
< access-control-allow-origin: *
< access-control-allow-credentials: true
< x-envoy-upstream-service-time: 3
```



# 8.4 HTTP Header Attributeにより、認証・認可を有効化する
Ref: https://istio.io/latest/docs/tasks/security/authorization/authz-deny/#explicitly-deny-a-request

[authorization_policy_deny_header.yaml](authorization_policy_deny_header.yaml)で,　`x-token: admin`を,　認可を有効化する条件に追加する
```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: deny-header
  namespace: istio-system 
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  action: DENY 
  rules:
  - to:
    - operation:
        paths: ["/headers"] 
        hosts: ["*.sni.com"] 
    when:
    - key: request.headers[x-token] 
      notValues: ["admin"] # <----- 上記の*.sni.com/headers且つ、Headerのx-token が admin出ない場合、拒否
```

Apply
```sh
# まずは前セクションで作った authorization policyを削除
kubectl delete -f authorization_policy_httpbin_path_host.yaml

kubectl apply -f authorization_policy_deny_header.yaml 
```

## "*.sni.com/headers"へのリクエストが、 "x-token"のheaderがないためエラーになる

```sh
# "x-token"をHeaderにパスしてないので失敗する
curl -v \
  --resolve "test.sni.com:$SECURE_INGRESS_PORT:$(host $(echo $INGRESS_HOST) | tail -1 | awk '{ print $4 }')" \
  --header "Authorization: Bearer $TOKEN" \
  "https://test.sni.com:$SECURE_INGRESS_PORT/headers" -k

# expected failing アウトプット
* Added test.sni.com:443:34.214.199.244 to DNS cache
* Hostname test.sni.com was found in DNS cache
*   Trying 34.214.199.244...
* TCP_NODELAY set
* Connected to test.sni.com (34.214.199.244) port 443 (#0)
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
*  subject: CN=*.sni.com
*  start date: Aug  7 08:12:52 2020 GMT
*  expire date: Aug  7 08:12:52 2021 GMT
*  issuer: CN=*.sni.com
*  SSL certificate verify result: self signed certificate (18), continuing anyway.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x7fa2f500ba00)
> GET /headers HTTP/2
> Host: test.sni.com
> User-Agent: curl/7.54.0
> Accept: */*
> Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6IkRIRmJwb0lVcXJZOHQyenBBMnFYZkNtcjVWTzVaRXI0UnpIVV8tZW52dlEiLCJ0eXAiOiJKV1QifQ.eyJleHAiOjQ2ODU5ODk3MDAsImZvbyI6ImJhciIsImlhdCI6MTUzMjM4OTcwMCwiaXNzIjoidGVzdGluZ0BzZWN1cmUuaXN0aW8uaW8iLCJzdWIiOiJ0ZXN0aW5nQHNlY3VyZS5pc3Rpby5pbyJ9.CfNnxWP2tcnR9q0vxyxweaF3ovQYHYZl82hAUsn21bwQd9zP7c-LS9qd_vpdLG4Tn1A15NxfCjp5f7QNBUo-KC9PJqYpgGbaXhaGx7bEdFWjcwv3nZzvc7M__ZpaCERdwU7igUmJqYGBYQ51vr2njU9ZimyKkfDe3axcyiBZde7G6dabliUosJvvKOPcKIWPccCgefSj_GNfwIip3-SsFdlR7BtbVUcqR-yv-XOxJ3Uc1MI0tz3uMiiZcyPV7sNCU4KRnemRIMHVOfuvHsU60_GhGbiSFzgPTAa9WTltbnarTbxudb_YEOx12JiwYToeX0DCPb43W1tzIBxgm8NxUg
> 
* Connection state changed (MAX_CONCURRENT_STREAMS updated)!
< HTTP/2 403 
< content-length: 19
< content-type: text/plain
< date: Sat, 08 Aug 2020 12:42:24 GMT
< server: istio-envoy
< 
* Connection #0 to host test.sni.com left intact
RBAC: access denied
```

## "*.sni.com/headers"へのリクエストが、 "x-token: admin"でないためエラーになる

```sh
# "x-token"のvalueが"admin"ではないのでエラーになる
curl -v \
  --resolve "test.sni.com:$SECURE_INGRESS_PORT:$(host $(echo $INGRESS_HOST) | tail -1 | awk '{ print $4 }')" \
  --header "Authorization: Bearer $TOKEN" \
  --header "x-token: test" \
  "https://test.sni.com:$SECURE_INGRESS_PORT/headers" -k

# expected failing アウトプット
* Added test.sni.com:443:34.214.199.244 to DNS cache
* Hostname test.sni.com was found in DNS cache
*   Trying 34.214.199.244...
* TCP_NODELAY set
* Connected to test.sni.com (34.214.199.244) port 443 (#0)
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
*  subject: CN=*.sni.com
*  start date: Aug  7 08:12:52 2020 GMT
*  expire date: Aug  7 08:12:52 2021 GMT
*  issuer: CN=*.sni.com
*  SSL certificate verify result: self signed certificate (18), continuing anyway.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x7ff51380ba00)
> GET /headers HTTP/2
> Host: test.sni.com
> User-Agent: curl/7.54.0
> Accept: */*
> Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6IkRIRmJwb0lVcXJZOHQyenBBMnFYZkNtcjVWTzVaRXI0UnpIVV8tZW52dlEiLCJ0eXAiOiJKV1QifQ.eyJleHAiOjQ2ODU5ODk3MDAsImZvbyI6ImJhciIsImlhdCI6MTUzMjM4OTcwMCwiaXNzIjoidGVzdGluZ0BzZWN1cmUuaXN0aW8uaW8iLCJzdWIiOiJ0ZXN0aW5nQHNlY3VyZS5pc3Rpby5pbyJ9.CfNnxWP2tcnR9q0vxyxweaF3ovQYHYZl82hAUsn21bwQd9zP7c-LS9qd_vpdLG4Tn1A15NxfCjp5f7QNBUo-KC9PJqYpgGbaXhaGx7bEdFWjcwv3nZzvc7M__ZpaCERdwU7igUmJqYGBYQ51vr2njU9ZimyKkfDe3axcyiBZde7G6dabliUosJvvKOPcKIWPccCgefSj_GNfwIip3-SsFdlR7BtbVUcqR-yv-XOxJ3Uc1MI0tz3uMiiZcyPV7sNCU4KRnemRIMHVOfuvHsU60_GhGbiSFzgPTAa9WTltbnarTbxudb_YEOx12JiwYToeX0DCPb43W1tzIBxgm8NxUg
> x-token: test # <------- admin is needed
> 
* Connection state changed (MAX_CONCURRENT_STREAMS updated)!
< HTTP/2 403 
< content-length: 19
< content-type: text/plain
< date: Sat, 08 Aug 2020 12:45:12 GMT
< server: istio-envoy
< 
* Connection #0 to host test.sni.com left intact
RBAC: access denied
```


## "*.sni.com/headers"へのリクエストが、 JTWをパスして且つ"x-token: admin"なので成功する

```sh
curl -v \
  --resolve "test.sni.com:$SECURE_INGRESS_PORT:$(host $(echo $INGRESS_HOST) | tail -1 | awk '{ print $4 }')" \
  --header "Authorization: Bearer $TOKEN" \
  --header "x-token: admin" \
  "https://test.sni.com:$SECURE_INGRESS_PORT/headers" -k

# expected successful アウトプット
* Added test.sni.com:443:34.214.199.244 to DNS cache
* Hostname test.sni.com was found in DNS cache
*   Trying 34.214.199.244...
* TCP_NODELAY set
* Connected to test.sni.com (34.214.199.244) port 443 (#0)
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
*  subject: CN=*.sni.com
*  start date: Aug  7 08:12:52 2020 GMT
*  expire date: Aug  7 08:12:52 2021 GMT
*  issuer: CN=*.sni.com
*  SSL certificate verify result: self signed certificate (18), continuing anyway.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x7f913480ba00)
> GET /headers HTTP/2
> Host: test.sni.com
> User-Agent: curl/7.54.0
> Accept: */*
> Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6IkRIRmJwb0lVcXJZOHQyenBBMnFYZkNtcjVWTzVaRXI0UnpIVV8tZW52dlEiLCJ0eXAiOiJKV1QifQ.eyJleHAiOjQ2ODU5ODk3MDAsImZvbyI6ImJhciIsImlhdCI6MTUzMjM4OTcwMCwiaXNzIjoidGVzdGluZ0BzZWN1cmUuaXN0aW8uaW8iLCJzdWIiOiJ0ZXN0aW5nQHNlY3VyZS5pc3Rpby5pbyJ9.CfNnxWP2tcnR9q0vxyxweaF3ovQYHYZl82hAUsn21bwQd9zP7c-LS9qd_vpdLG4Tn1A15NxfCjp5f7QNBUo-KC9PJqYpgGbaXhaGx7bEdFWjcwv3nZzvc7M__ZpaCERdwU7igUmJqYGBYQ51vr2njU9ZimyKkfDe3axcyiBZde7G6dabliUosJvvKOPcKIWPccCgefSj_GNfwIip3-SsFdlR7BtbVUcqR-yv-XOxJ3Uc1MI0tz3uMiiZcyPV7sNCU4KRnemRIMHVOfuvHsU60_GhGbiSFzgPTAa9WTltbnarTbxudb_YEOx12JiwYToeX0DCPb43W1tzIBxgm8NxUg
> x-token: admin
> 
* Connection state changed (MAX_CONCURRENT_STREAMS updated)!
< HTTP/2 200 
< server: istio-envoy
< date: Sat, 08 Aug 2020 12:44:09 GMT
< content-type: application/json
< content-length: 1656
< access-control-allow-origin: *
< access-control-allow-credentials: true
< x-envoy-upstream-service-time: 3
< 
{
  "headers": {
    "Accept": "*/*", 
    "Content-Length": "0", 
    "Host": "test.sni.com", 
    "User-Agent": "curl/7.54.0", 
    "X-B3-Sampled": "1", 
    "X-B3-Spanid": "b3ffaa414a45c70c", 
    "X-B3-Traceid": "0a31a764cba65071b3ffaa414a45c70c", 
    "X-Envoy-Decorator-Operation": "httpbin.default.svc.cluster.local:80/headers", 
    "X-Envoy-Internal": "true", 
    "X-Envoy-Peer-Metadata": "ChoKCkNMVVNURVJfSUQSDBoKS3ViZXJuZXRlcwofCgxJTlNUQU5DRV9JUFMSDxoNMTkyLjE2OC42Ni43NAqWAgoGTEFCRUxTEosCKogCCh0KA2FwcBIWGhRpc3Rpby1pbmdyZXNzZ2F0ZXdheQoTCgVjaGFydBIKGghnYXRld2F5cwoUCghoZXJpdGFnZRIIGgZUaWxsZXIKGQoFaXN0aW8SEBoOaW5ncmVzc2dhdGV3YXkKIQoRcG9kLXRlbXBsYXRlLWhhc2gSDBoKNWQ4NjlmNWJiZgoSCgdyZWxlYXNlEgcaBWlzdGlvCjkKH3NlcnZpY2UuaXN0aW8uaW8vY2Fub25pY2FsLW5hbWUSFhoUaXN0aW8taW5ncmVzc2dhdGV3YXkKLwojc2VydmljZS5pc3Rpby5pby9jYW5vbmljYWwtcmV2aXNpb24SCBoGbGF0ZXN0ChoKB01FU0hfSUQSDxoNY2x1c3Rlci5sb2NhbAovCgROQU1FEicaJWlzdGlvLWluZ3Jlc3NnYXRld2F5LTVkODY5ZjViYmYtYnZweHMKGwoJTkFNRVNQQUNFEg4aDGlzdGlvLXN5c3RlbQpdCgVPV05FUhJUGlJrdWJlcm5ldGVzOi8vYXBpcy9hcHBzL3YxL25hbWVzcGFjZXMvaXN0aW8tc3lzdGVtL2RlcGxveW1lbnRzL2lzdGlvLWluZ3Jlc3NnYXRld2F5CqcBChFQTEFURk9STV9NRVRBREFUQRKRASqOAQogCg5hd3NfYWNjb3VudF9pZBIOGgwxNjQ5MjU1OTYzMTUKJQoVYXdzX2F2YWlsYWJpbGl0eV96b25lEgwaCnVzLXdlc3QtMmQKKAoPYXdzX2luc3RhbmNlX2lkEhUaE2ktMDQ3Yzc0MTQ3NjZhZjIwNmUKGQoKYXdzX3JlZ2lvbhILGgl1cy13ZXN0LTIKOQoPU0VSVklDRV9BQ0NPVU5UEiYaJGlzdGlvLWluZ3Jlc3NnYXRld2F5LXNlcnZpY2UtYWNjb3VudAonCg1XT1JLTE9BRF9OQU1FEhYaFGlzdGlvLWluZ3Jlc3NnYXRld2F5", 
    "X-Envoy-Peer-Metadata-Id": "router~192.168.66.74~istio-ingressgateway-5d869f5bbf-bvpxs.istio-system~istio-system.svc.cluster.local", 
    "X-Token": "admin" # <------- admin is needed
  }
}
```


# 8.5 指定したSource IPに対して、JWTのEnd-User Authorizationを有効化する
Refs: 
- https://istio.io/latest/docs/tasks/security/authorization/authz-ingress/#ip-based-allow-list-and-deny-list
- https://istio.io/latest/docs/reference/config/security/authorization-policy/

まずは自分のIPを取得する
```sh
CLIENT_IP=$(curl $INGRESS_HOST/ip -L -k -s | grep "origin" | cut -d'"' -f 4) && echo $CLIENT_IP

# アウトプット
192.168.69.89
```

```sh
# まずは前セクションで作った authorization policyを削除
kubectl delete -f authorization_policy_deny_header.yaml
```

アプライ
```yaml
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: deny-ip
  namespace: istio-system 
spec:
  selector:
    matchLabels:
      app: istio-ingressgateway
  action: DENY
  rules:
  - from:
    - source:
       ipBlocks: ["$CLIENT_IP"] # <--- このIPからのリクエスト
EOF
```


テスト
```sh
curl $INGRESS_HOST/ip -v -L -k

# expected failing アウトプット
*   Trying 54.149.143.27...
* TCP_NODELAY set
* Connected to a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com (54.149.143.27) port 80 (#0)
> GET /ip HTTP/1.1
> Host: a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com
> User-Agent: curl/7.54.0
> Accept: */*
> 
< HTTP/1.1 403 Forbidden
< content-length: 19
< content-type: text/plain
< date: Sat, 08 Aug 2020 11:30:28 GMT
< server: istio-envoy
< 
* Connection #0 to host a5a1acc36239d46038f3dd828465c946-706040707.us-west-2.elb.amazonaws.com left intact
RBAC: access denied # <----- 認可失敗
```

最後にauthorization policyを削除
```
kubectl delete -f authorization_policy_deny_ip.yaml
```