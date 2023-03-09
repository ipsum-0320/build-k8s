# 接 ../node/main.sh 的拉取 Docker 镜像


# 生成默认配置 kubeadm-config.yaml
kubeadm config print init-defaults > kubeadm-config.yaml

# 最终修改如下
# apiVersion: kubeadm.k8s.io/v1beta3
# bootstrapTokens:
# - groups:
#   - system:bootstrappers:kubeadm:default-node-token
#   token: abcdef.0123456789abcdef
#   ttl: 24h0m0s
#   usages:
#   - signing
#   - authentication
# kind: InitConfiguration
# localAPIEndpoint:
#   advertiseAddress: 101.34.112.190 # 指定master节点的IP地址（公网）
#   bindPort: 6443
# nodeRegistration:
#   criSocket: /var/run/dockershim.sock
#   imagePullPolicy: IfNotPresent
#   name: master01  # 改成master的主机名
#   taints: null
# ---
# apiServer:
#   timeoutForControlPlane: 4m0s
# apiVersion: kubeadm.k8s.io/v1beta3
# certificatesDir: /etc/kubernetes/pki
# clusterName: kubernetes
# controllerManager: {}
# dns: {}
# etcd:
#   local:
#     dataDir: /var/lib/etcd
# imageRepository: registry.aliyuncs.com/google_containers  # 默认为k8s.gcr.io，但是网络不通，所以要替换为阿里云镜像
# kind: ClusterConfiguration
# kubernetesVersion: 1.23.6  # 指定kubernetes版本号，使用kubeadm config print init-defaults生成的即可
# networking:
#   dnsDomain: cluster.local
#   serviceSubnet: 10.96.0.0/12
#   podSubnet: 10.244.0.0/16  # 指定pod网段，10.244.0.0/16用于匹配flannel默认网段
# scheduler: {}

# 检查环境
kubeadm init phase preflight --config=kubeadm-config.yaml 

#初始化 kubeadm 集群
kubeadm init --config=kubeadm-config.yaml

# 如果是内网搭建，那就没什么问题；如果是云服务器搭建则会有问题，下面是解决办法
vim /etc/kubernetes/manifests/etcd.yaml
# 改为     
# - --listen-client-urls=https://127.0.0.1:2379
# - --listen-peer-urls=https://127.0.0.1:2380

# 重启 kubelet 进程
systemctl stop kubelet
netstat -anp | grep kube # 之后通过 kill -9 杀掉进程
systemctl start kubelet
kubeadm init --config=kubeadm-config.yaml --skip-phases=preflight,certs,kubeconfig,kubelet-start,control-plane,etcd

# 准备配置文件
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 安装 CN 网络
curl https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml >> kube-flannel.yml
chmod 777 kube-flannel.yml 
kubectl apply -f kube-flannel.yml




