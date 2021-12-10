# 14. eksctl Manated Nodesのデメリット

# 1. EC2のブートストラップUserdata scriptを設定できない
チャプター10のIRSAで少し触れましたが、インスタンスメタデータへのアクセスをブロックするコマンドは、Userdataスクリプトで設定するのが望ましいですが、eksctl Manated Nodesではこれができません。

```bash
yum install -y iptables-services
iptables --insert FORWARD 1 --in-interface eni+ --destination 169.254.169.254/32 --jump DROP
iptables-save | tee /etc/sysconfig/iptables 
systemctl enable --now iptables
```

__他のいくつかのデメリットは__　この記事にある通り([eksctl doc](https://eksctl.io/usage/eks-managed-nodes/#feature-parity-with-unmanaged-nodegroups)):
> Control over the node bootstrapping process and customization of the kubelet are not supported. This includes the following fields: classicLoadBalancerNames, maxPodsPerNode, __taints__, targetGroupARNs, preBootstrapCommands, __overrideBootstrapCommand__, clusterDNS and __kubeletExtraConfig__.


例えば、EKSワーカーノードのEC2にEFSを自動でマウントしたい場合、Userdataスクリプトで設定するのが一般的ですが、下記のコマンドが設定できません。

```bash
sudo mkdir /mnt/efs

sudo mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-xxxxx.efs.us-east-1.amazonaws.com:/ /mnt/efs

echo 'fs-xxxxx.efs.us-east-1.amazonaws.com:/ /mnt/efs nfs defaults,vers=4.1 0 0' >> /etc/fstab
```

なので、本番運用では[Terraform と __Unmanaged Node Groups__](https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/examples/irsa/main.tf#L64)を使うことを推奨します。


# 2.  Unmanaged Node Groupsのように、EKS Worker nodesをASGのオプションからTaintできない

本番環境ではノードは、`env=prod`や`prod-only=true:PreferNoSchedule`のようにK8sのLabelやTaintがされています。 もしAuto Scaling Groupのノードが起動してきた時に、それらのLabelやTaintが追加されないと,  __NodeAffinity__ や __Tolerance__ が指定されているPodが新しいNodeに振り当てられなくなり、このようなエラーが表示されます。 
```
pod didn't trigger scale-up (it wouldn't fit if a new node is added)
```


# 解決方法: Unmanaged NodeをTerraformを使ってディプロイ

下記のTerraform.tfvarsの一部が、実際に本番運用で使っている、unmanaged ワーカーグループの設定です。
ここでUserdata scriptのオプション(`additional_userdata`)で 1) インスタンスメタデータへのアクセスをブロック, 2) EFSをマウント, そして 3) K8s taintをノードに追加をしています。

```sh
# note (only for unmanaged node group)
# gotcha: need to use kubelet_extra_args to propagate taints/labels to K8s node, because ASG tags not being propagated to k8s node objects.
# ref: https://github.com/kubernetes/autoscaler/issues/1793#issuecomment-517417680
# ref: https://github.com/kubernetes/autoscaler/issues/2434#issuecomment-576479025
worker_groups = [
  {
    name          = "worker-group-staging-1"
    instance_type = "m3.xlarge"
    asg_max_size  = 3
    asg_desired_capacity = 1 # this will be ignored if cluster autoscaler is enabled: asg_desired_capacity: https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/docs/autoscaling.md#notes

    # ref: https://docs.aws.amazon.com/eks/latest/userguide/restrict-ec2-credential-access.html  
    # this userdata will block access to metadata to avoid pods from using node's IAM instance profile, and also create /mnt/efs and auto-mount EFS to it using fstab. Note: userdata script doesn't resolve shell variable defined within
    additional_userdata  = "yum install -y iptables-services; iptables --insert FORWARD 1 --in-interface eni+ --destination 169.254.169.254/32 --jump DROP; iptables-save | tee /etc/sysconfig/iptables; systemctl enable --now iptables; sudo mkdir /mnt/efs; sudo mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-xxxxx.efs.us-east-1.amazonaws.com:/ /mnt/efs; echo 'fs-xxxxx.efs.us-east-1.amazonaws.com:/ /mnt/efs nfs defaults,vers=4.1 0 0' >> /etc/fstab"
    kubelet_extra_args   = "--node-labels=env=staging,unmanaged-node=true --register-with-taints=staging-only=true:PreferNoSchedule" # for unmanaged nodes, taints and labels work only with extra-arg, not ASG tags. Ref: https://aws.amazon.com/blogs/opensource/improvements-eks-worker-node-provisioning/
    tags = [
      {
        "key"                 = "unmanaged-node"
        "propagate_at_launch" = "true"
        "value"               = "true"
      },
      {
        "key"                 = "k8s.io/cluster-autoscaler/enabled" # need this tag so clusterautoscaler auto-discovers node group: https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/docs/autoscaling.md
        "propagate_at_launch" = "true"
        "value"               = "true"
      },
    ]
  },
}
```