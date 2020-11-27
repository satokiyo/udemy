# 11. (ベストプラクティス) Scaling: Cluster Autoscaler (CA) 

Ref: https://docs.aws.amazon.com/eks/latest/userguide/cluster-autoscaler.html

![alt text](../imgs/ca.png "CA")

![alt text](../imgs/eks_aws_architecture_with_apps_ingress_access_logs.png "K8s Ingress")

Cluster Autoscaler (CA) はクラスターノード（EC2インスタンス）の数を自動でスケールアップ・ダウンします。（AWS Auto Scaling Groupを利用）

CAの設定に必要な3つのステップ:
1. AWS ASGのタグを追加
2. cluster autoscalerへ認可（Authorization）のIAM パミッションをIRSA (Podレベル)かEC2 Instance Profile（ノードレベル）で追加by instance profile
3. cluster-autoscalerをHelm ChartとしてEKS clusterにインストール



# ステップ1: AWS ASGのタグを追加

まずはcluster-autoscalerがどのASGをスケールアップ・ダウンするのか見つけるために、ASGにタグを追加 
```
k8s.io/cluster-autoscaler/enabled = true
```
そして
```
k8s.io/cluster-autoscaler/<YOUR CLUSTER NAME> = owned
```

ちなみに, [AWS EKS Managed Node Groups](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html) は自動的にこのタグは追加されている:
> Nodes launched as part of a managed node group are __automatically tagged for auto-discovery__ by the Kubernetes cluster autoscaler and you can use the node group to apply Kubernetes labels to nodes and update them at any time.

> Amazon EKS tags managed node group resources so that they are configured to use the Kubernetes Cluster Autoscaler.

![alt text](../imgs/managed_group_ca_tags.png "K8s Architecture")



# (IAMベストプラクティス) ステップ2: cluster autoscalerへ認可（Authorization）のIAM パミッションをIRSA (Podレベル)かEC2 Instance Profile（ノードレベル）で追加by instance profile

CAはASGのサイズを変更したりするので、以下のIAM permissonsが必要です
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeTags",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "ec2:DescribeLaunchTemplateVersions"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
```

IAM policy `EKSFromEksctlClusterAutoscaler`をIAM Consoleから作成し, IAM policy arn `arn:aws:iam::xxxxxxx:policy/EKSFromEksctlClusterAutoscaler`を記録

![alt text](../imgs/ca_iam_policy.png "K8s Architecture")


Service account `cluster-autoscaler-aws-cluster-autoscaler`を`kube-system` namespaceに作成し、IAM roleも同時に作成
```bash
eksctl create iamserviceaccount \
                --name cluster-autoscaler-aws-cluster-autoscaler \
                --namespace kube-system \
                --cluster eks-from-eksctl \
                --attach-policy-arn arn:aws:iam::266981300450:policy/EKSFromEksctlClusterAutoscaler \
                --approve \
                --region us-west-2

# アウトプット
[ℹ]  eksctl version 0.21.0
[ℹ]  using region us-west-2
[ℹ]  3 existing iamserviceaccount(s) (default/clusterautoscaler,default/irsa-service-account,kube-system/clusterautoscaler) will be excluded
[ℹ]  1 iamserviceaccount (kube-system/cluster-autoscaler-aws-cluster-autoscaler) was included (based on the include/exclude rules)
[ℹ]  combined exclude rules: default/clusterautoscaler,default/irsa-service-account,kube-system/clusterautoscaler
[ℹ]  no iamserviceaccounts present in the current set were excluded by the filter
[!]  serviceaccounts that exists in Kubernetes will be excluded, use --override-existing-serviceaccounts to override
[ℹ]  1 task: { 2 sequential sub-tasks: { create IAM role for serviceaccount "kube-system/cluster-autoscaler-aws-cluster-autoscaler", create serviceaccount "kube-system/cluster-autoscaler-aws-cluster-autoscaler" } }
[ℹ]  building iamserviceaccount stack "eksctl-eks-from-eksctl-addon-iamserviceaccount-kube-system-cluster-autoscaler-aws-cluster-autoscaler"
[ℹ]  deploying stack "eksctl-eks-from-eksctl-addon-iamserviceaccount-kube-system-cluster-autoscaler-aws-cluster-autoscaler"
```

IAM consoleで作成されたIAM Roleをチェック:
![alt text](../imgs/ca_iam_role.png "K8s Architecture")


# ステップ3: Cluster Autoscaler(CA）をHelm chartでインストール
Ref: https://github.com/helm/charts/tree/master/stable/cluster-autoscaler

まずは[overrides.yaml](overrides.yaml)を編集。
```yaml
awsRegion: us-west-2

rbac:
  create: true # <-------- Service AccountでRoleを使う（IRSA） ref: https://github.com/kubernetes/autoscaler/issues/1507
  serviceAccount:
    create: false # because Service account and IAM role already created by `eksctl create iamserviceaccount`

autoDiscovery:
  clusterName: eks-from-eksctl   # <--------クラスターの名前
  enabled: true
```

そして`cluster-autoscaler`という名前のHelm Chartのリリース名でインストール (Helmが名前を追加して最終的には`cluster-autoscaler-aws-cluster-autoscaler`というservice accountが作られる。この名前がステップ２で指定したService Account名とマッチしないといけない)。またこのCAを`kube-system`namespaceにインストール。 (__重要__: IRSAの設定で指定したService Account名とNamespace名を指定)
```
helm install cluster-autoscaler \
    stable/cluster-autoscaler \
    --namespace kube-system \
    --values overrides.yaml
```

アウトプット
```sh
NAME: cluster-autoscaler
LAST DEPLOYED: Mon Jun 15 00:01:00 2020
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
To verify that cluster-autoscaler has started, run:

  kubectl --namespace=kube-system get pods -l "app=aws-cluster-autoscaler,release=cluster-autoscaler"
```

cluster-autoscaler podが起動しているのをチェック:
```bash
$ kubectl --namespace=kube-system get pods | grep cluster-autoscaler

# アウトプット
NAME                                                        READY   STATUS    RESTARTS   AGE
cluster-autoscaler-aws-cluster-autoscaler-5545d4b97-9ztpm   1/1     Running   0          3m
```


# CAのAuto Scalingをテスト

テストPodを起動
```sh
kubectl apply -f test_irsa_ca.yaml

kubectl get pod test-irsa -n kube-system

# コンテナ内にShellで接続
kubectl exec -it test-irsa -n kube-system bash
```

環境変数が設定されているのを確認
```
$ env | grep AWS
AWS_ROLE_ARN=arn:aws:iam::266981300450:role/eksctl-eks-from-eksctl-addon-iamserviceaccou-Role1-1KN3XZTA0TTJF
AWS_WEB_IDENTITY_TOKEN_FILE=/var/run/secrets/eks.amazonaws.com/serviceaccount/token
```

PodがASGのパミッションを持っているかテスト
```
$ aws autoscaling describe-auto-scaling-instances --region us-east-1
```

アウトプット
```
{
    "AutoScalingInstances": [
        {
            "InstanceId": "i-05b5c07094b1732af",
            "InstanceType": "m3.large",
            "AutoScalingGroupName": "eks-ue2-eks-demo-120200507173038542300000005",
            "AvailabilityZone": "us-east-1b",
            "LifecycleState": "InService",
            "HealthStatus": "HEALTHY",
            "LaunchConfigurationName": "eks-ue2-eks-demo-120200507173032181200000003",
            "ProtectedFromScaleIn": false
        },
        {
            "InstanceId": "i-0ea21df8315c87976",
            "InstanceType": "m3.large",
            "AutoScalingGroupName": "eks-ue2-eks-demo-120200507173038542900000006",
            "AvailabilityZone": "us-east-1b",
            "LifecycleState": "InService",
            "HealthStatus": "HEALTHY",
            "LaunchConfigurationName": 
```

他のASG permissionもテスト
```
aws autoscaling set-desired-capacity \
    --auto-scaling-group-name eks-b0b99a83-0d9b-59f6-ea8b-1d94c6da14db \
    --desired-capacity 2 \
    --region us-west-2
```

Nginx PodのリソースリクエストをYAMLで定義
```yaml
        resources:
          limits:
            cpu: 2500m
            memory: 2500Mi
          requests:
            cpu: 1400m # 意図的にCPUを多くリクエスト
            memory: 1400Mi
```

__注意__: もしリクエストしたCPU/memoryがサーバーのキャパシティを越えると下記のエラーが起るので注意
```
'NotTriggerScaleUp' pod didn't trigger scale-up (it wouldn't fit if a new node is added
``` 


Nginx Podをディプロイして、スケールアップをテスト
```
kubectl apply -f test_scaling.yaml
```

deploymentとpodをチェック
```
kubectl get deploy
kubectl get pod -o wide
```

ワーカーノードのリソース使用量をチェック
```
kubectl top nodes
```

アウトプット
```
NAME                                           CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
ip-192-168-20-213.us-west-2.compute.internal   307m         15%    630Mi           18%   
```

Nginx Deploymentを１０個にスケールアップ
```
kubectl scale --replicas=10 deployment/test-scaling
```

Podのステータスをチェックすると`Pending`ステータスになっているのが見える
```
kubectl get pod -w
NAME                                READY   STATUS    RESTARTS   AGE
test_scaling-98ffcf4f7-2skcx   0/1     Pending   0          42s
test_scaling-98ffcf4f7-5wsgn   0/1     Pending   0          42s
test_scaling-98ffcf4f7-99gmv   0/1     Pending   0          42s
test_scaling-98ffcf4f7-hw57s   0/1     Pending   0          42s
test_scaling-98ffcf4f7-lmq6l   0/1     Pending   0          42s
test_scaling-98ffcf4f7-n5hss   1/1     Running   0          42s
test_scaling-98ffcf4f7-rp9ng   1/1     Running   0          5m11s
test_scaling-98ffcf4f7-rzdtj   1/1     Running   0          42s
test_scaling-98ffcf4f7-scpb8   0/1     Pending   0          42s
test_scaling-98ffcf4f7-wt2vf   0/1     Pending   0          42s
```

Pendingになっているpodのイベントをチェック
```
kubectl describe pod test_scaling-5b9dfddc87-ttnrt
```

`pod triggered scale-up`イベントが確認できる
```
  Type     Reason            Age                From                Message
  ----     ------            ----               ----                -------
  Warning  FailedScheduling  25s (x2 over 25s)  default-scheduler   0/2 nodes are available: 2 Insufficient cpu.
  Normal   TriggeredScaleUp  24s                cluster-autoscaler  pod triggered scale-up: [{eks-38b956c7-0ec3-a597-f1b3-d12e58aee6de 2->4 (max: 4)}]
```

ここのライン 
```
0/2 nodes are available: 2 Insufficient cpu.

cluster-autoscaler  pod triggered scale-up: [{eks-38b956c7-0ec3-a597-f1b3-d12e58aee6de 2->4 (max: 4)}]
```

Clusterautoscalerのログを確認
```
kubectl logs cluster-autoscaler-aws-cluster-autoscaler-67bb6f64f5-cpw7h -n kube-system
```

アウトプット
```
I0507 18:12:18.872668       1 scale_up.go:348] Skipping node group eks-ue2-eks-demo-120200507173038542300000005 - max size reached

I0507 18:12:18.873470       1 static_autoscaler.go:439] Scale down status: unneededOnly=true lastScaleUpTime=2020-05-07 18:10:18.182849499 +0000 UTC m=+2290.588530135 lastScaleDownDeleteTime=2020-05-07 17:32:28.323356185 +0000 UTC m=+20.729036698 lastScaleDownFailTime=2020-05-07 17:32:28.323357798 +0000 UTC m=+20.729038331 scaleDownForbidden=false isDeleteInProgress=false scaleDownInCooldown=true
I0507 18:12:18.873897       1 event.go:281] Event(v1.ObjectReference{Kind:"Pod", Namespace:"test", Name:"test_scaling-7499fc797-r8dsz", UID:"7bf9bd56-2f73-417e-9949-7722b0df5772", APIVersion:"v1", ResourceVersion:"270633", FieldPath:""}): type: 'Normal' reason: 'NotTriggerScaleUp' pod didn't trigger scale-up (it wouldn't fit if a new node is added): 1 node(s) didn't match node selector, 1 max node group size reached
```


# クリーンアップ

```
kubectl delete -f test_irsa_ca.yaml
kubectl delete -f test_scaling.yaml
```