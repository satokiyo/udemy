# 13. Networking: デフォルトのAWS-VPC-CNI (Container Network Interface) のデメリット: EKSワーカーノードのインスタンスタイプによって、Pod IPの数が制限される

Refs:
- [AWS EKS Instance types & Pod IP size spreadsheet](https://docs.google.com/spreadsheets/d/1MCdsmN7fWbebscGizcK6dAaPGS-8T_dYxWp0IdwkMKI/edit#gid=1549051942)
- [List of EC2 instance types and max # of Pod IPs](https://github.com/awslabs/amazon-eks-ami/blob/master/files/eni-max-pods.txt)

もしEC2のPod IPsが使い切られてしまうと、`0/1 nodes are available: 1 Insufficient pods.`というエラーが表示されます
```
Events:
  Type     Reason            Age                  From               Message
  ----     ------            ----                 ----               -------
  Warning  FailedScheduling  33s (x4 over 2m22s)  default-scheduler  0/1 nodes are available: 1 Insufficient pods.
```

# 解決方法

EKSワーカーノードのインスタンスタイプを大きくするか、カスタムCNI（例：Calico）をインストールする必要があります。