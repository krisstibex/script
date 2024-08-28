# script-not-found
小作品合集

* 部分脚本修改于网络上的其他脚本
* ~~Power by ChatGPT 有bug别找我~~
## 目录

### sub-store-manager
- 安装node版的sub-store
```
bash <(curl -fsSL https://github.com/krisstibex/script/raw/main/sub-store-manager/sub-store-manager.sh)
```
### snell
- 一键安装snell+shadowtls
```
bash <(curl -fsSL https://s.mikutabs.eu.org/snell)
```
### sing-box
- 一键安装sing-box
- 依赖
```
apt update && apt -y install curl wget tar socat net-tools jq git openssl uuid-runtime build-essential zlib1g-dev libssl-dev libevent-dev dnsutils cron
```
- 脚本
```
wget -N -O /root/singbox.sh https://github.com/krisstibex/script/raw/main/sing-box/Install.sh && chmod +x /root/singbox.sh && ln -sf /root/singbox.sh /usr/local/bin/singbox && bash /root/singbox.sh
```
### Tor
- 一键搭建obfs4网桥
```
bash <(curl -fsSL https://github.com/krisstibex/script/raw/main/obfs4-tor-bridge/obfs4-tor-bridge.sh)
```

## 我还在用的其他脚本

### docker
- 安装docker
```
curl -sSL https://get.docker.com | bash
```
### vps一键工具箱
- 功能多多
```
curl -sS -O https://raw.githubusercontent.com/kejilion/sh/main/kejilion.sh && chmod +x kejilion.sh && ./kejilion.sh
```
### dd脚本
- 搞砸了怎么办 当然是重装系统啦
```
wget -qO InstallNET.sh https://github.com/leitbogioro/Tools/raw/master/Linux_reinstall/InstallNET.sh && bash InstallNET.sh -ubuntu 24.04 -pwd <你的密码>
```
### 电报自走机器人
- 
