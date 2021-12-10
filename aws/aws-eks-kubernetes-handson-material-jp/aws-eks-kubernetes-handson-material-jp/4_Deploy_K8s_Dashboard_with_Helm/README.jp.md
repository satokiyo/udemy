# 4. Kuberenetesダッシュボードをインストール
![alt text](../imgs/k8s_dashboard_admin_permission.png "K8s Architecture")

# 4.1 ステップ1: Metrics Serverをインストール
```
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.6/components.yaml
```

metrics-server　のdeploymentをチェック
```bash
kubectl get deployment metrics-server -n kube-system
```

アウトプット
```bash
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
metrics-server   1/1     1            1           82s
```

# 4.2 ステップ2: Dashboard v2.0.0をインストール
Refs: 
- https://kubernetes.github.io/dashboard/
- https://docs.aws.amazon.com/eks/latest/userguide/dashboard-tutorial.html

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
```

`kubernetes-dashboard` namespaceにリソースが作られたのがわかる
```bash
namespace/kubernetes-dashboard created
serviceaccount/kubernetes-dashboard created
service/kubernetes-dashboard created
secret/kubernetes-dashboard-certs created
secret/kubernetes-dashboard-csrf created
secret/kubernetes-dashboard-key-holder created
configmap/kubernetes-dashboard-settings created
role.rbac.authorization.k8s.io/kubernetes-dashboard created
clusterrole.rbac.authorization.k8s.io/kubernetes-dashboard created
rolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
clusterrolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
deployment.apps/kubernetes-dashboard created
service/dashboard-metrics-scraper created
deployment.apps/dashboard-metrics-scraper created
```

ダッシュボードにログインするためのトークン（パスワードみたいなもの）をSecretから取得
```
kubectl describe secret $(k get secret -n kubernetes-dashboard | grep kubernetes-dashboard-token | awk '{ print $1 }') -n kubernetes-dashboard
```

ローカルホストから API serverにセキュアなトンネルを作る
```
kubectl proxy

# このURLをブラウザーからアクセス
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

![alt text](../imgs/k8s_dashboard_without_permission.png "K8s Architecture")

デフォルトのservice account `serviceaccount/kubernetes-dashboard`のトークンなので、パミッションが足りずリソースが見えない。

# 4.3 ステップ3: RBAC (Role Based Access Control)を使い、ダッシュボードでMetricsを見るための必要なパミッションを設定

[eks-admin-service-account.yaml](eks-admin-service-account.yaml)
```
apiVersion: v1
kind: ServiceAccount
metadata:
  name: eks-admin
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: eks-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin # this is the cluster admin role
subjects:
- kind: ServiceAccount
  name: eks-admin
  namespace: kube-system
```

アプライ
```
kubectl apply -f eks-admin-service-account.yaml
```

`kube-system` namespaceに作られたService acccountをチェック
```
kubectl get serviceaccount -n kube-system | grep eks-admin
eks-admin                            1         52s
```

`eks-admin` serviceaccountのトークンを取得
```
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}')
```

ローカルホストから API serverにセキュアなトンネルを作る
```
kubectl proxy

# このURLをブラウザーからアクセス
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

ダッシュボードで全ての namespaces上のリソースが見える
![alt text](../imgs/k8s_dashboard_admin_permission.png "K8s Architecture")


# 4.4 K8s ダッシュボードの解説


## Dashboardをアンインストールする
```
kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml

kubectl delete -f eks-admin-service-account.yaml
```