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


## 杂项

### 快捷获取sing-box版本号
* release
```
curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest \
    | grep tag_name \
    | cut -d ":" -f2 \
    | sed 's/\"//g;s/\,//g;s/\ //g;s/v//'
```
* beta
```
curl -s https://api.github.com/repos/SagerNet/sing-box/releases \
    | grep tag_name \
    | cut -d ":" -f2 \
    | sed 's/\"//g;s/\,//g;s/\ //g;s/v//' \
    | sort -V \
    | tail -n 1
```
