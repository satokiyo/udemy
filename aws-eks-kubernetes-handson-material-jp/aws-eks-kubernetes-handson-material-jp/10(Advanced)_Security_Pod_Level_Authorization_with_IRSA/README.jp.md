# 10. (ベストプラクティス) Security: IRSA(IAM Role for Service Account）を使い、PodレベルのAWSへの認可を設定


# 1. Service Accountを使ったPodのK8sクラスターへの認証（Authentication）をおさらい

![alt text](../imgs/pod_authentication_2.png "K8s Architecture")

1. まずPodのリソースYAMLでService Accountを指定すると, Podの代わりのService AccountがAPI serverに認証するためのトークンを、コンテナ内のファイルにVolumeがマウントされる（`/var/run/secrets/kubernetes.io/serviceaccount/token`）
2. Podはコンテナ内のファイルにVolumeがマウントされたトークンでAPI serverに認証される


# 2. EKS NodeのInstance Profileを使ったPodのAWSリソースへの認可（Authorization）

![alt text](../imgs/pod_authorization_aws_2.png "K8s Architecture")

1. PodはEKSワーカーノード上に起動し, そのEC2インスタンスにはAWS IAM instance profileがアタッチされている
2. つまりPod内のコンテナはEC2のインスタンスメタデータのURL（`169.254.169.254/latest/meta-data/iam/security-credentials/IAM_ROLE_NAME`）から、一時的なIAM credentialsを取得することができる

コンテナをEKSに起動して、シェルでコンテナ内に入り、インスタンスメタデータのURL（`169.254.169.254/latest/meta-data/iam/security-credentials/IAM_ROLE_NAME`）をチェック

```sh
# コンテナをEKSに起動
kubectl run --image curlimages/curl --restart Never --command curl -- /bin/sh -c "sleep 500"

# シェルでコンテナ内に入り
kubectl exec -it curl sh

# インスタンスメタデータのURLにアクセス
curl 169.254.169.254/latest/meta-data/iam/security-credentials
```

ここで問題なのが最小権限のルールが破られて、どのPodも同じEC2のAWS Instance ProfileにアタッチされたAWS IAM Roleにアクセスができることです。（つまり、ノードレベルのAWS認可）


# 3. IRSA(IAM Role for Service Account、またはPodレベルのIAM認可）アーキテクチャの解剖

ref: https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/


![alt text](../imgs/eks_irsa_2.png "K8s Architecture")

1. `kubectl apply -f`コマンドを使ってPodを起動する時, YAMLがAPI Serverに送られ、API ServerにあるAmazon EKS Pod Identity webhookが、常時YAMLリソースにService AccountとそのService AccountのAnnotationにAWS IAM Role ARNがあるか見ています
2. `irsa-service-account`というService Accountに eks.amazonaws.com/role-arn annotationがあるので, webhookがAWS_ROLE_ARNやAWS_WEB_IDENTITY_TOKEN_FILEという環境変数をPodにInjectoします（aws-iam-token projected volumeがマウントされる）
3. Service accoountがOIDC経由でAWS IAMから認証が取れた後、JWT トークンをOIDCから受け取り `AWS_WEB_IDENTITY_TOKEN_FILE`に保存します
4. コンテナが`aws s3 ls`などのAWS CLIコマンドを実行すると、Podが`AWS_WEB_IDENTITY_TOKEN_FILE`に保存されたトークンを使って`sts:assume-role-with-web-identity`コマンドを実行し、AWS IAM roleをAssumeします。そのIAM Roleの一時的なCredentialsを使って`aws s3 ls`が実行されます



# setup 1: OIDCプロバイダーを作成し、クラスターにアソシエイト

`eksctl create cluster`コマンドで既にOIDC provider URLは作られているので、下記のコマンドはスキップ
```bash
# get the cluster’s identity issuer URL
ISSUER_URL=$(aws eks describe-cluster \
                       --name eks-from-eksctl \
                       --query cluster.identity.oidc.issuer \
                       --output text)

# create OIDC provider
aws iam create-open-id-connect-provider \
          --url $ISSUER_URL \
          --thumbprint-list $ROOT_CA_FINGERPRINT \
          --client-id-list sts.amazonaws.com
```


OIDC providerをEKSクラスターにリンク
```bash
eksctl utils associate-iam-oidc-provider \
            --region=us-west-2 \
            --cluster=eks-from-eksctl \
            --approve

# アウトプット
[ℹ]  eksctl version 0.21.0
[ℹ]  using region us-west-2
[ℹ]  will create IAM Open ID Connect provider for cluster "eks-from-eksctl" in "us-west-2"
[✔]  created IAM Open ID Connect provider for cluster "eks-from-eksctl" in "us-west-2"
```

# setup 2: NamespaceとServiceAccountとOIDCエンドポイントを指定したIAM assumable roleを作成し、k8s service accountにIAM role ARNのAnnotationを追加

1. デモとして、IAM roleを作成し`arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess`のIAMポリシーを追加
2. Service account`irsa-service-account`を作成し, １で作ったIAM role ARNをAnnotationに追加

```bash
eksctl create iamserviceaccount \
                --name irsa-service-account \
                --namespace default \
                --cluster eks-from-eksctl \
                --attach-policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess \
                --approve \
                --region us-west-2

# アウトプット
[ℹ]  eksctl version 0.21.0
[ℹ]  using region us-west-2
[ℹ]  1 iamserviceaccount (default/irsa-service-account) was included (based on the include/exclude rules)
[!]  serviceaccounts that exists in Kubernetes will be excluded, use --override-existing-serviceaccounts to override
[ℹ]  1 task: { 2 sequential sub-tasks: { create IAM role for serviceaccount "default/irsa-service-account", create serviceaccount "default/irsa-service-account" } }
[ℹ]  building iamserviceaccount stack "eksctl-eks-from-eksctl-addon-iamserviceaccount-default-irsa-service-account"
[ℹ]  deploying stack "eksctl-eks-from-eksctl-addon-iamserviceaccount-default-irsa-service-account"
[ℹ]  created serviceaccount "default/irsa-service-account"
```

新しく作られたAWS IAM role `eksctl-eks-from-eksctl-addon-iamserviceaccou-Role1-1S8X0CMRPPPLY` をコンソールでチェック

![alt text](../imgs/irsa_iam_role.png "K8s Ingress")


また、新しく作られたservice account`irsa-service-account`の詳細をチェック
```bash
$ kubectl describe serviceaccount irsa-service-account

# アウトプット
Name:                irsa-service-account
Namespace:           default
Labels:              <none>
Annotations:         eks.amazonaws.com/role-arn: arn:aws:iam::xxxxxx:role/eksctl-eks-from-eksctl-addon-iamserviceaccou-Role1-1S8X0CMRPPPLY  # <--- ここにIAM Role ARNをAnnotationとして追加
Image pull secrets:  <none>
Mountable secrets:   irsa-service-account-token-qcjzn
Tokens:              irsa-service-account-token-qcjzn
Events:              <none>
```

# setup 3: Pod YAMLでService accountの名前を指定

`aws/aws-cli` dockerイメージからDeploymentのYAMLを作成し、`irsa-service-account` service accountも指定
```bash
kubectl run irsa-iam-test \
    --image amazon/aws-cli  \
    --serviceaccount irsa-service-account \
    --dry-run -o yaml \
    --command -- /bin/sh -c "sleep 500" \
    > deployment_irsa_test.yaml
```

[deployment_irsa_test.yaml](deployment_irsa_test.yaml)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    run: irsa-iam-test
  name: irsa-iam-test
spec:
  replicas: 1
  selector:
    matchLabels:
      run: irsa-iam-test
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        run: irsa-iam-test
    spec:
      containers:
      - command:
        - /bin/sh
        - -c
        - sleep 500
        image: amazon/aws-cli
        name: irsa-iam-test
        resources: {}
      serviceAccountName: irsa-service-account
```

Deploymentを作成
```
kubectl apply -f deployment_irsa_test.yaml
```

コンテナ内にシェルで接続し、IAM roleをAssumeしてS3のreadができるかテスト
```bash
kubectl exec -it irsa-iam-test-cf8d66797-kx2s2  sh

# 環境変数を表示
sh-4.2# env

AWS_ROLE_ARN=arn:aws:iam::xxxxxx:role/eksctl-eks-from-eksctl-addon-iamserviceaccou-Role1-1S8X0CMRPPPLY  # <--- IAM role ARNがインジェクトされている
GUESTBOOK_PORT_3000_TCP_ADDR=10.100.53.19
HOSTNAME=irsa-iam-test-cf8d66797-kx2s2
AWS_WEB_IDENTITY_TOKEN_FILE=/var/run/secrets/eks.amazonaws.com/serviceaccount/token # <---- IAM roleをAssumeするためのJWT token

# awsバージョンをチェック
sh-4.2# aws --version
aws-cli/2.0.22 Python/3.7.3 Linux/4.14.181-140.257.amzn2.x86_64 botocore/2.0.0dev26

# list S3
sh-4.2# aws s3 ls
2020-06-13 16:27:43 eks-from-eksctl-elb-access-log
```

現在のIAM identityをチェック
```
sh-4.2# aws sts get-caller-identity
{
    "UserId": "AROAS6KA4SFRWOLUNLZAK:botocore-session-1592141699",
    "Account": "xxxxxx",
    "Arn": "arn:aws:sts::xxxxxx:assumed-role/eksctl-eks-from-eksctl-addon-iamserviceaccou-Role1-1S8X0CMRPPPLY/botocore-session-1592141699"
}
```


## 図解でおさらい?!

![alt text](../imgs/eks_irsa_2.png "K8s Architecture")

1. `kubectl apply -f`コマンドを使ってPodを起動する時, YAMLがAPI Serverに送られ、API ServerにあるAmazon EKS Pod Identity webhookが、常時YAMLリソースにService AccountとそのService AccountのAnnotationにAWS IAM Role ARNがあるか見ています
2. `irsa-service-account`というService Accountに eks.amazonaws.com/role-arn annotationがあるので, webhookがAWS_ROLE_ARNやAWS_WEB_IDENTITY_TOKEN_FILEという環境変数をPodにInjectoします（aws-iam-token projected volumeがマウントされる）
3. Service accoountがOIDC経由でAWS IAMから認証が取れた後、JWT トークンをOIDCから受け取り `AWS_WEB_IDENTITY_TOKEN_FILE`に保存します
4. コンテナが`aws s3 ls`などのAWS CLIコマンドを実行すると、Podが`AWS_WEB_IDENTITY_TOKEN_FILE`に保存されたトークンを使って`sts:assume-role-with-web-identity`コマンドを実行し、AWS IAM roleをAssumeします。そのIAM Roleの一時的なCredentialsを使って`aws s3 ls`が実行されます


## まだここで終わらない！Podは未だにEC2 instance profileにアクセスが可能

EC2のインスタンスメタデータにアクセステスト
```sh
kubectl exec -it irsa-iam-test-cf8d66797-hc5f9  sh

curl 169.254.169.254/latest/meta-data/iam/security-credentials/eksctl-eks-from-eksctl-nodegroup-NodeInstanceRole-R3EFEQC9U6U

# アウトプット
{
  "Code" : "Success",
  "LastUpdated" : "2020-06-14T14:33:13Z",
  "Type" : "AWS-HMAC",
  "AccessKeyId" : "XXXXXXXXXXXXX",
  "SecretAccessKey" : "XXXXXXXXXXXXX",
  "Token" : "IQoJb3JpZ2luX2VjEBcaCXVzLXdlc3QtMiJHMEUCIEopyCSxERjDyyIk/cdtKLAtnBBMCaYTb8MnBuHfqjUVAiEAlmSiH88+wjEiHo3SS0USnGV4puAOblv6LwAloJQ1cu4qvQMIkP//////////ARACGgwyMDI1MzY0MjM3NzkiDIG3Fa09R5JhGpvhISqRA34u+YtI3KbV3coXwZgo3FRMLoFlNHeCpOnz+hgjkfY+MA0SNcWhnD3/7v2CRYE9/CaYwF5hedEkSMxrZq5z2b+qQOSSrGaVRU/c8c6JA8CnpvqvhPEdpupxFgwH2YHYFFu9UeqMD7u9Lrg7FxrCfkgpSQyz+aEfifGy2J5+Cr8P5ddKZhmGSTeWM01foC1dF8tQPnlPgYDGKJL1QRJUkxh4i6RUMq8HruxDy9D+S3x+Ig5vKByKfE9S8pAP99VxYswuTYNr2sGAasvnDCQBeUZ81s0JDeWfFTzQ+Cc2/D4lZt+nsEVvqN+pCvHpxDSIC0WJZ9rs/X+YFRxp4XlJI5YLR/gqA7LIRVva+hehfeTICLFcPkuizZcOVAFWHjnoOM17GpnwzNrLxSOdYzny2B/RgnhFdUpjC7Nj7lj2gsWDVN7q24A+fW5jXVFbjQzvZTGFJWpWhWtYDQCuYNiemy27koEOvRgKsSzYu01NV+K4yFHz3uqJkrbveOW76KadIy3P6+qI159cIDCJNw7oq9YCMLTqmPcFOusB0Dh7qUOeb1LoMFjFamdhz9VLYFdd3zLlC0q/1nIldZQLo42nhEzSgJ/xAHYdyQ/BHK4H9z32zggk8x8grq/cXihCMlmN2Ku5PBR2ScdDnhodbMAjafjP9xLE7MYUa8z+aKq3qT85ZIQAU07JpUh5ccqYlgcPuPo6NrJrHV31wDaYfApTTzrO1AUFygVcih3TCLLYPJEN3bKHTtpunkAN90iLOPS8g6OcJBJUAK9d+oZH/g+UWhf21X3DUaRxQMv80By13AbzxChxTLqizDBSf8dXWrrVf8yehVxgHz21fqipCmKqcohQXEXCfQ==",
  "Expiration" : "2020-06-14T20:33:36Z"
}
```


# 4. EC2のインスタンスメタデータへのアクセスをブロック

EKSワーカーノードにSSH
```sh
eval $(ssh-agent)
ssh-add -k ~/.ssh/
ssh -A ec2-user@192.168.20.213
```

iptablesコマンドを実行
```bash
yum install -y iptables-services
iptables --insert FORWARD 1 --in-interface eni+ --destination 169.254.169.254/32 --jump DROP
iptables-save | tee /etc/sysconfig/iptables 
systemctl enable --now iptables
```


# 5. eksctl とeksctl Manated Nodesのデメリット
最適な方法は, AutoScalingGroupのlaunch configurationのUserdata scriptで設定するとことで、新しく起動するEC2インスタンス全てのインスタンスメタデータへのアクセスをブロックされる。

しかs、eksctl Manated Nodesのデメリットは、EC2のBootstrap userdata scriptをカスタマイズできないことである([eksctl doc](https://eksctl.io/usage/eks-managed-nodes/#feature-parity-with-unmanaged-nodegroups)):
> Control over the node bootstrapping process and customization of the kubelet are not supported. This includes the following fields: classicLoadBalancerNames, maxPodsPerNode, __taints__, targetGroupARNs, preBootstrapCommands, __overrideBootstrapCommand__, clusterDNS and __kubeletExtraConfig__.