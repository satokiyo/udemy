# 8. 他のコンテナオーケストレーションとは？

## 8.1 Docker Swarm
使われてません。

## 8.2 RedHat OpenShift
IBMに2019年に3,4兆円で買収されました。OpenShiftはKubernetesをベースにして、さらにイメージRegistryやCI/CDパイプラインがデフォルトでついてくるので、おすすめです。

つまり、OpenShift内のPrivate Image Registryに新しいドッカーイメージをPushすれば、自動でHookがTriggerされて、新しいPodが自動でDeployされます。

Managed OpenShiftサービスはまだクラウド上では少なくMicrosoft　Azureだけですが、2020年5月現在、AWSがManaged OpenShiftを提供するというニュースがありました。

## 8.3 CloudFoundry
唯一と言ってもいいOpenSourceのツールです。OnPremで使う例をたまに聞くくらいです。


---
NEXT > [9_Build_Web_App](../9_Build_Web_App/README.md)