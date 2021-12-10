# 8. Monitoring: PrometheusとGrafana

# Prometheus アーキテクチャ
![alt text](../imgs/prometheus_architecture.png "Prometheus Architecture")


# PrometheusをHelm Chartからインストール
```bash
# まずはnamespaceを作成
kubectl create namespace prometheus

helm install prometheus stable/prometheus \
    --namespace prometheus \
    --set alertmanager.persistentVolume.storageClass="gp2" \
    --set server.persistentVolume.storageClass="gp2"
```

アウトプット
```sh
NAME: prometheus
LAST DEPLOYED: 
NAMESPACE: prometheus
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The Prometheus server can be accessed via port 80 on the following DNS name from within your cluster:
prometheus-server.prometheus.svc.cluster.local


The Prometheus PushGateway can be accessed via port 9091 on the following DNS name from within your cluster:
prometheus-pushgateway.prometheus.svc.cluster.local


Get the Prometheus server URL by running these commands in the same shell:
  export POD_NAME=$(kubectl get pods --namespace prometheus -l "app=prometheus,component=server" -o jsonpath="{.items[0].metadata.name}")
  kubectl --namespace prometheus port-forward $POD_NAME 9090
```

ディプロイされたリソースをチェック
```
kubectl get pods,deploy,svc,serviceaccount -n prometheus
```

`alertmanager`, `kube-state-metrics`, `pushgateway`, そして`prometheus-server`などが作られたのがわかる
```
NAME                                                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.extensions/prometheus-alertmanager         1/1     1            1           5m28s
deployment.extensions/prometheus-kube-state-metrics   1/1     1            1           5m28s
deployment.extensions/prometheus-pushgateway          1/1     1            1           5m28s
deployment.extensions/prometheus-server               1/1     1            1           5m28s
```

kubectlでProxyをローカルホストからK8s api serverへ作る
```sh
export POD_NAME=$(kubectl get pods --namespace prometheus -l "app=prometheus,component=server" -o jsonpath="{.items[0].metadata.name}")

kubectl --namespace prometheus port-forward $POD_NAME 9090

# ブラウザーからアクセス
http://127.0.0.1:9090/
```

これがPrometheusのダッシュボード:
![alt text](../imgs/prometheus_metrics.png "Prometheus Metrics")
![alt text](../imgs/prometheus_targets.png "Prometheus Targets")



# GrafanaをHelm Chartからインストール
```sh
kubectl create namespace grafana

helm install grafana stable/grafana \
    --namespace grafana \
    --set persistence.storageClassName="gp2" \
    --set persistence.enabled=true \
    --set adminPassword='EKS!sAWSome' \
    --set datasources."datasources\.yaml".apiVersion=1 \
    --set datasources."datasources\.yaml".datasources[0].name=Prometheus \
    --set datasources."datasources\.yaml".datasources[0].type=prometheus \
    --set datasources."datasources\.yaml".datasources[0].url=http://prometheus-server.prometheus.svc.cluster.local \
    --set datasources."datasources\.yaml".datasources[0].access=proxy \
    --set datasources."datasources\.yaml".datasources[0].isDefault=true \
    --set service.type=ClusterIP
```

アウトプット
```
NAME: grafana
LAST DEPLOYED: Sun Jun 14 02:24:33 2020
NAMESPACE: grafana
STATUS: deployed
REVISION: 1
NOTES:
1. Get your 'admin' user password by running:

   kubectl get secret --namespace grafana grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

2. The Grafana server can be accessed via port 80 on the following DNS name from within your cluster:

   grafana.grafana.svc.cluster.local

   Get the Grafana URL to visit by running these commands in the same shell:

     export POD_NAME=$(kubectl get pods --namespace grafana -l "app=grafana,release=grafana" -o jsonpath="{.items[0].metadata.name}")
     kubectl --namespace grafana port-forward $POD_NAME 3000

3. Login with the password from step 1 and the username: admin
```

ディプロイされたリソースをチェック
```
kubectl get pods,deploy,svc,serviceaccount -n grafana
```

kubectlでProxyをローカルホストからK8s api serverへ作る
```sh
# GrafanaのpasswordをSecretから取得
kubectl get secret --namespace grafana grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo


export POD_NAME=$(kubectl get pods --namespace grafana -o jsonpath="{.items[0].metadata.name}")

kubectl --namespace grafana port-forward $POD_NAME 3000
```

# GrafanaのDashboardを紹介

ダッシュボードのテンプレをインポートする場合:

”＋” icon > dashboard ID `3119`をタイプ > ‘Prometheus’ をdata sourcesとしてDropdownから選択.

![alt text](../imgs/grafana_setting.png "grafana setting")


GrafanaのDashboardでいろんなMetricsがVisualizeされているのが見える
![alt text](../imgs/grafana_dashboard.png "grafana Dashboard")


# 特に役立つGrafanaのコミュニティDashboard 

- [K8 Cluster Detail Dashboard](https://grafana.com/grafana/dashboards/10856)
- [K8s Cluster Summary](https://grafana.com/grafana/dashboards/8685)
- [Kubernetes cluster monitoring](https://grafana.com/grafana/dashboards/315)


# アンインストール 
```
helm uninstall prometheus -n prometheus
helm uninstall grafana -n grafana
```