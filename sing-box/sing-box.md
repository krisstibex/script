# sing-box一键脚本

## 使用方法
1.安装依赖
```
apt update && apt -y install curl wget tar socat net-tools jq git openssl uuid-runtime build-essential zlib1g-dev libssl-dev libevent-dev dnsutils cron
```
2.一键脚本
```
wget -N -O /root/singbox.sh https://github.com/krisstibex/script/raw/main/sing-box/Install.sh && chmod +x /root/singbox.sh && ln -sf /root/singbox.sh /usr/local/bin/singbox && bash /root/singbox.sh
```
