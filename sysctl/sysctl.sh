#!/bin/bash

# 一键优化 sysctl 设置并启用 BBR 和 CAKE

cat <<EOF >> /etc/sysctl.conf

# 网络性能优化
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_syncookies = 1

# 启用 BBR 拥塞控制
net.core.default_qdisc = fq_codel
net.ipv4.tcp_congestion_control = bbr

# 安全性优化
net.ipv4.ip_forward = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

# 内存和资源管理
fs.file-max = 2097152
vm.swappiness = 10
fs.suid_dumpable = 0
kernel.shmmax = 68719476736
kernel.shmall = 4294967296

EOF

# 启用 CAKE 队列管理
tc qdisc replace dev eth0 root cake bandwidth 100mbit besteffort

sysctl -p
