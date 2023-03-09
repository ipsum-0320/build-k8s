$ vim k8s-pre-install-centos.sh

#!/bin/sh

function set_base() {
  # 关闭防火墙，PS：如果使用云服务器，还需要在云服务器的控制台中把防火墙关闭了或者允许所有端口
  systemctl stop firewalld
  systemctl disable firewalld

  # 关闭SELinux，这样做的目的是：为了让容器能读取主机文件系统
  setenforce 0

  # 永久关闭swap分区交换，kubeadm规定，一定要关闭
  swapoff -a
  sed -ri 's/.*swap.*/#&/' /etc/fstab

  # iptables配置
  cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

  cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

  # iptables生效参数
  sysctl --system
}

set_base
