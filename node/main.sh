chmod 777 k8s-pre-install-centos.sh && ./k8s-pre-install-centos.sh

# 如果是 master 节点请将 node01 改为 master
hostnamectl set-hostname node01

# hosts 文件需要加入集群内所有的云服务器，包括公网 IP 和 hostname
vim /etc/hosts

# 安装 Docker
yum install -y yum-utils
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce-20.10.14-3.el7 docker-ce-cli-20.10.14-3.el7 containerd.io docker-compose-plugin

# 配置 Docker 守护程序
mkdir /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "registry-mirrors": ["https://6ijb8ubo.mirror.aliyuncs.com"],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

# 启动docker，并设置为开机启动
systemctl enable docker
systemctl daemon-reload
systemctl restart docker
systemctl status docker # 确保是 running 状态

# 确认 Cgroup Driver 为 systemd
docker info | grep "Cgroup Driver"

# 安装 kubeadm
cat > /etc/yum.repos.d/kubernetes.repo << EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
yum makecache # 更新 yum

# 安装 kubeadm、kubectl 和 kubelet
sudo yum install -y kubelet-1.23.6 kubeadm-1.23.6 kubectl-1.23.6 --disableexcludes=kubernetes

# 启动 kubelet，并设置为开机启动
systemctl start kubelet
systemctl enable kubelet

# 替换镜像源后拉取 Docker 镜像
kubeadm config images list
vim kubeadm-config-image.yaml
kubeadm config images list --config kubeadm-config-image.yaml # 确认一下
kubeadm config images pull --config kubeadm-config-image.yaml # 拉取镜像

# master 节点不需要执行这一步，将 node 加入 Kubernates 集群
kubeadm join 192.168.1.200:6443 --token abcdef.0123456789abcdef \
    --discovery-token-ca-cert-hash sha256:af2a6e096cb404da729ef3802e77482f0a8a579fa602d7c071ef5c5415aac748
# 注意 token 和 sha256 值是不同的。

# 如果上面这个命令丢失了，可以通过在 master 中执行 kubeadm token create --print-join-command 来获取。

# 各个服务器的网络地址
47.113.144.248  master
39.96.212.224   node00
47.115.215.127  node01
43.136.115.216  node02
47.120.14.60    node03
47.113.201.179  node04
47.120.8.61     node05




