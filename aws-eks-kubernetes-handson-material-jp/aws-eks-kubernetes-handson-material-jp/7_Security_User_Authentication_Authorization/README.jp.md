# 7. Security: AWS Userの認証 (aws-iam-authenticator) と 認可(RBAC: Role Based Access Control)

![alt text](../imgs/eks_aws_authenticatio_authorization.png "K8s Architecture")


# 7.1 AWS IAM UserのK8sクラスターへの認証（Authentication）のプロセスを解剖

![alt text](../imgs/eks_user_authentication.png "K8s Architecture")

1. `kubectl ...` コマンドがリクエストをMasterノードのAPIサーバーに送ります。 `kubectl`は AWS EKSを利用している場合, AWS IAM user ARN か IAM Role ARNをAPI serverに送ります。
2. API server がARN を`aws-iam-authenticator` サーバーに送り, AWS IAMと確認してもらいます。
3. `aws-iam-authenticator` がAWS IAMから確認できたら,　次に`kube-system` namespace内の`aws-auth` configmap をチェックし、そのAWSユーザーがK8sユーザーとして存在するか認可のチェックします 
4. 認可の確認後、API servierがユーザーからのリクエストどうりプロセスするか、リクエストを拒否します (“You must be logged in to the server (Unauthorized)”) 


# 7.2 Kubeconfig と aws-auth ConfigMap
```
kubectl config view
```

アウトプット
```
users:
- name: 1592048816494086000@eks-from-eksctl.us-west-2.eksctl.io
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      args:
      - token
      - -i
      - eks-from-eksctl
      command: aws-iam-authenticator
      env:
      - name: AWS_STS_REGIONAL_ENDPOINTS
        value: regional
      - name: AWS_DEFAULT_REGION
        value: us-west-2
```

EKSクラスター内で認可された AWS IAM user とIAM role ARNsのconfigmap`aws-auth`をYAMLで表示
```
kubectl get configmap aws-auth -n kube-system -o yaml
```

アウトプット
```yaml
apiVersion: v1
data:
  mapRoles: |
    - groups:
      - system:bootstrappers
      - system:nodes
      rolearn: arn:aws:iam::xxxxxxxx:role/eksctl-eks-from-eksctl-nodegroup-NodeInstanceRole-R3EFEQC9U6U
      username: system:node:{{EC2PrivateDNSName}}
kind: ConfigMap
metadata:
  creationTimestamp: "2020-06-13T12:01:54Z"
  name: aws-auth
  namespace: kube-system
  resourceVersion: "666"
  selfLink: /api/v1/namespaces/kube-system/configmaps/aws-auth
  uid: 37b70aec-2c62-4010-956b-b3b7cd473f61
```

下記の部分でわかることは、
```yaml
mapRoles: |
    - groups:   # K8s User Group which is tied to ClusterRole
      - system:bootstrappers 
      - system:nodes
      rolearn: arn:aws:iam::xxxxxxxx:role/eksctl-eks-from-eksctl-nodegroup-NodeInstanceRole-R3EFEQC9U6U  # AWS IAM user
      username: system:node:{{EC2PrivateDNSName}} 
```

1. `rolearn: arn:aws:iam::xxxxxxxx:role/eksctl-eks-from-eksctl-nodegroup-NodeInstanceRole-R3EFEQC9U6U` がK8sのユーザーである `system:node:{{EC2PrivateDNSName}}`とリンクされている
2. またK8sユーザーグループ `system:bootstrappers`と`system:nodes`にも追加されている


# 7.3 新しいAWS IAMユーザーを作成

1. 新しいAWS IAM userをAWS IAM consoleから作り、AWS access keyとsecret access keyを作成
2. AWS profile を`~/.aws/credentials`に追加し、AWS access keyとsecret access keyを保存
```
vim ~/.aws/credentials
```

```
[eks-viewer]
aws_access_key_id = ここに追加
aws_secret_access_key = ここに追加
region = us-west-2
```

`eks-viewer`AWS Userとしてアクセステスト
```
export AWS_PROFILE=eks-viewer
aws sts get-caller-identity
```

アウトプット
```json
{
    "UserId": "REDUCTED",
    "Account": "xxxxx",
    "Arn": "arn:aws:iam::xxxx:user/eks-viewer"
}
```

最後に、元のAWS PROFILEにスイッチ。
```
export AWS_PROFILE=eks-editor
aws sts get-caller-identity

export AWS_PROFILE=eks-admin
aws sts get-caller-identity
```


# 7.4 K8s Cluster内でAWS IAM Usersをルートユーザーとして認可 (注意: アンチパターン)

Refs: 
- https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html
- https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles

```
kubectl edit -n kube-system configmap/aws-auth
```

`aws-auth` configmapに新しいAWS IAM userのARNを追加
```yaml
mapUsers: |
    - userarn: arn:aws:iam::111122223333:user/eks-viewer   # AWS IAM user
      username: this-aws-iam-user-name-will-have-root-access
      groups:
      - system:masters  # K8s User Group
```

YAMLを表示して反映されたかチェック
```bash
$ kubectl get -n kube-system configmap/aws-auth -o yaml

# アウトプット
apiVersion: v1
data:
  mapRoles: |
    - groups:
      - system:bootstrappers
      - system:nodes
      rolearn: arn:aws:iam::xxxxxxxxxxx:role/eksctl-eks-from-eksctl-nodegroup-NodeInstanceRole-R3EFEQC9U6U
      username: system:node:{{EC2PrivateDNSName}}
  mapUsers: |
    - userarn: arn:aws:iam::xxxxxxxxxxxxx:user/eks-viewer
      username: this-aws-iam-user-name-will-have-root-access
      groups:
      - system:masters  # <-------- アンチパターン：ここでルートユーザーを指定している
kind: ConfigMap
metadata:
  creationTimestamp: "2020-06-13T12:01:54Z"
  name: aws-auth
  namespace: kube-system
  resourceVersion: "40749"
  selfLink: /api/v1/namespaces/kube-system/configmaps/aws-auth
```

AWS IAM userの `eks-viewer`として K8s cluster内での認可をチェック
```sh
# switch AWS IAM user by changing AWS profile
export AWS_PROFILE=eks-viewer

# kubectlでREAD/GETのコマンドをしてみる
kubectl get pod
NAME                 READY   STATUS    RESTARTS   AGE
guestbook-dxkpd      1/1     Running   0          4h6m
guestbook-fsqx8      1/1     Running   0          4h6m
guestbook-nnrjc      1/1     Running   0          4h6m
redis-master-6dbj4   1/1     Running   0          4h8m
redis-slave-c6wtv    1/1     Running   0          4h7m
redis-slave-qccp6    1/1     Running   0          4h7m
```

他のパミッションもチェック
```
$ kubectl auth can-i create deployments
yes

$ kubectl auth can-i delete deployments
yes

$ kubectl auth can-i delete ClusterRole
yes
```

このAWS IAM userは`system:masters`というK8sユーザーグループにバインドされている
```yaml
mapUsers: |
    - userarn: arn:aws:iam::111122223333:user/eks-viewer   # AWS IAM user
      username: this-aws-iam-user-name-will-have-root-access
      groups: 
      - system:masters  # K8s User Group
```

しかし`system:masters`はK8sクラスター内でルートアクセスを持つので、推奨しません！
```sh
# "cluster-admin" ClusterRoleBindingをチェック
$ kubectl get clusterrolebindings/cluster-admin -o yaml

# アウトプット
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  creationTimestamp: "2020-06-13T11:57:34Z"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: cluster-admin
  resourceVersion: "104"
  selfLink: /apis/rbac.authorization.k8s.io/v1/clusterrolebindings/cluster-admin
  uid: b2905280-b865-4ede-b256-7ed39873e1eb
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin  # <-------  k8sユーザーグループ名が保持するClusterRoleは"cluster-admin"
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:masters # <-------  k8sユーザーグループ名
```


これは __最小権限の原則__（principle of least priviledge）に反します。

最小権限をAWS IAM userにバインドするには, 正しいK8s ClusterRoleBindingを作る必要があります。

# 7.5 ClusterRoleBinding (RBAC - Role Based Access Control)を作成し、K8sユーザーの権限をコントロール

Refs: 
- https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles
- https://github.com/kubernetes-sigs/aws-iam-authenticator/issues/139#issuecomment-417400851

`kube-system`Namespace内には, デフォルトで既に作られたClusterRoleがあります（例：`edit`, `view`, etc）

clusterroleを表示
```
kubectl get clusterrole -n kube-system
````

`view` ClusterRoleの詳細を表示
```
kubectl describe clusterrole view -n kube-system
```

アウトプット
```sh
Name:         view
Labels:       kubernetes.io/bootstrapping=rbac-defaults
              rbac.authorization.k8s.io/aggregate-to-admin=true
Annotations:  rbac.authorization.kubernetes.io/autoupdate: true
PolicyRule:
  Resources                                    Non-Resource URLs  Resource Names  Verbs
  ---------                                    -----------------  --------------  -----
  configmaps                                   []                 []              [create delete deletecollection patch update get list watch]
  endpoints                                    []                 []              [create delete deletecollection patch update get list watch]
.
.
.
  resourcequotas                               []                 []              [get list watch]
  services/status                              []                 []              [get list watch]
  controllerrevisions.apps                     []                 []              [get list watch]
  daemonsets.apps/status                       []                 []              [get list watch]
  deployments.apps/status                      []                 []              [get list watch]
  deployments.extensions/status                []                 []              [get list watch]
  ingresses.extensions/status                  []                 []              [get list watch]                     []                 []              [get list watch]
  pods.metrics.k8s.io                          []                 []              [get list watch]
  ingresses.networking.k8s.io/status           []                 []              [get list watch]
  poddisruptionbudgets.policy/status           []                 []              [get list watch]
  serviceaccounts                              []                 []              [impersonate create delete deletecollection patch update get list watch]
```

このclusterroleはまだどのK8s userにも使われていません. この`view` ClusterRoleを新しいK8s userである `system:viewer`にバインドするために, `ClusterRoleBinding`を作成します。

ClusterrolebindingのYAMLを生成
```sh
kubectl create clusterrolebinding system:viewer \
    --clusterrole=view \
    --group=system:viewer \
    --dry-run -o yaml > clusterrolebinding_system_viewer.yaml

cat clusterrolebinding_system_viewer.yaml
```

アウトプット
```sh
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  creationTimestamp: null
  name: system:viewer
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view  # <------　Clusterrole
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:viewer   # <-----K8s user group
```

アプライ
```
kubectl apply -f clusterrolebinding_system_viewer.yaml
```

ClusterRoleBinding `system:viewer` がClusterRole `view`にバインドされているかチェック
```sh
$ kubectl describe clusterrolebinding system:viewer 

Name:         system:viewer
Labels:       <none>
Annotations:  kubectl.kubernetes.io/last-applied-configuration:
                {"apiVersion":"rbac.authorization.k8s.io/v1beta1","kind":"ClusterRoleBinding","metadata":{"annotations":{},"creationTimestamp":null,"name"...
Role:
  Kind:  ClusterRole  # <------　Clusterrole
  Name:  view
Subjects:
  Kind   Name           Namespace
  ----   ----           --------- 
  Group  system:viewer   # <-----K8s user group
```

# 7.6 (ClusterRoleBindingにより)権限が設定されたK8s User GroupsにAWS IAMユーザーをバインド

元のAWS PROFILEにスイッチ
```sh
export AWS_PROFILE=YOUR_ORIGINAL_PROFILE
```

そしてconfigmapを編集
```
kubectl edit -n kube-system configmap/aws-auth
```

今回は以前選択した`system:masters`というK8sユーザーグループではなく, 新しく作成したClusterRoleBinding `system:viewer`で指定した`system:viewer`というK8sユーザーグループを指定
```yaml
mapUsers: |
    - userarn: arn:aws:iam::111122223333:user/eks-viewer  # AWS IAM User
      username: eks-viewer
      groups:
      - system:viewer  # K8s User Group which is tied to ClusterRole
```

AWS IAM user `eks-viewer`としてK8sクラスター内の認可をテスト
```sh
# switch AWS IAM user by changing AWS profile
export AWS_PROFILE=eks-viewer

# kubectlでREAD/GETのコマンドをしてみる
kubectl get pod
NAME                 READY   STATUS    RESTARTS   AGE
guestbook-dxkpd      1/1     Running   0          4h6m
guestbook-fsqx8      1/1     Running   0          4h6m
guestbook-nnrjc      1/1     Running   0          4h6m
redis-master-6dbj4   1/1     Running   0          4h8m
redis-slave-c6wtv    1/1     Running   0          4h7m
redis-slave-qccp6    1/1     Running   0          4h7m
```

他のパミッションもチェック
```sh
$ kubectl auth can-i create deployments
no  # <------ 想定どおり

$ kubectl auth can-i delete deployments
no

$ kubectl auth can-i delete ClusterRole
no
```

`eks-viewer` AWS IAM userは`system:viewer` K8sユーザーグループにバインドされていて, `view` ClusterRoleパミッションしかないので、Create/Deleteコマンドは拒否される
```
# try to create namespace
$ kubectl create namespace test

Error from server (Forbidden): namespaces is forbidden: User "eks-viewer" cannot create resource "namespaces" in API group "" at the cluster scope
```


## 図解でおさらい
![alt text](../imgs/eks_user_authentication_2.png "K8s Architecture")


# 7.7 AWS IAM Role を K8s Cluster内に認証

本番運用では、AWS IAM userはIAM roleをAssumeし、ライフサイクルの短い（90分ほどでAuto　Rotateする）temporary credentialsを使うべきです。

AWS IAM roleを認可したい場合は, IAM Role ARNsを`aws-auth` configmapに追加
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - groups:
      - system:bootstrappers
      - system:nodes
      rolearn: arn:aws:iam::xxxxxxxx:role/eksctl-eks-from-eksctl-nodegroup-NodeInstanceRole-R3EFEQC9U6U
      username: system:node:{{EC2PrivateDNSName}}
    - groups:  # <----- new IAM role entry
      - system:viewer  # <----- K8s User Group
      rolearn: arn:aws:iam::xxxxxxxx:role/eks-viewer-role  # AWS IAM role
      username: eks-viewer
    - groups:  # <----- new IAM role entry
      - system:editor   # <----- K8s User Group
      rolearn: arn:aws:iam::xxxxxxxx:role/eks-editor-role  # AWS IAM role
      username: eks-editor
  # it's best practice to use IAM role rather than IAM user's access key
  # mapUsers: |
  #   - userarn: arn:aws:iam::xxxxxxxxx:user/eks-viewer
  #     username: eks-viewer
  #     groups:
  #     - system:viewer
  #   - userarn: arn:aws:iam::xxxxxxxx:user/eks-editor
  #     username: eks-editor
  #     groups:
  #     - system:editor
```