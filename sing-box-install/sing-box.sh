#!/bin/bash
set -e -o pipefail

# 初始化参数
OUTPUT_PATH=""
REPO_URL=""
BRANCH=""
REPO_DESC=""
GOOS="linux"  # 默认为 linux

# 解析输入参数
while getopts "o:a:d:" opt; do
  case $opt in
    o) OUTPUT_PATH="$OPTARG";;
    a) 
      case $OPTARG in
        main) 
          REPO_URL="https://github.com/SagerNet/sing-box"
          BRANCH="main"
          REPO_DESC="sing-box 稳定版"
          ;;
        beta) 
          REPO_URL="https://github.com/SagerNet/sing-box"
          BRANCH="dev-next"
          REPO_DESC="sing-box beta版"
          ;;
        1) 
          REPO_URL="https://github.com/PuerNya/sing-box"
          BRANCH="building"
          REPO_DESC="sing-box 下游分支 (PuerNya)"
          ;;
        2) 
          REPO_URL="https://github.com/qjebbs/sing-box"
          BRANCH="main"
          REPO_DESC="sing-box 下游分支 (qjebbs)"
          ;;
        3) 
          REPO_URL="https://github.com/rnetx/sing-box"
          BRANCH="dev-next"
          REPO_DESC="sing-box 下游分支 (rnetx)"
          ;;
        *) 
          echo "Invalid option for -a. Available options: main, beta, 1, 2, 3."
          exit 1
          ;;
      esac
      ;;
    d) GOOS="$OPTARG";;  # 设置GOOS的值
    *) echo "Usage: $0 [-o output_path] [-a option] [-d goos]" >&2; exit 1;;
  esac
done

# 如果没有使用 -a 参数，显示菜单
if [ -z "$REPO_URL" ]; then
  echo "请选择要使用的仓库和分支:"
  echo "1) sing-box 稳定版 (https://github.com/SagerNet/sing-box, 分支: main)"
  echo "2) sing-box beta版 (https://github.com/SagerNet/sing-box, 分支: dev-next)"
  echo "3) sing-box 下游分支 (PuerNya) (https://github.com/PuerNya/sing-box, 分支: building)"
  echo "4) sing-box 下游分支 (qjebbs) (https://github.com/qjebbs/sing-box, 分支: main)"
  echo "5) sing-box 下游分支 (rnetx) (https://github.com/rnetx/sing-box, 分支: dev-next)"
  read -p "请输入选项 (1-5): " choice

  case $choice in
    1) 
      REPO_URL="https://github.com/SagerNet/sing-box"
      BRANCH="main"
      REPO_DESC="sing-box稳定版"
      ;;
    2) 
      REPO_URL="https://github.com/SagerNet/sing-box"
      BRANCH="dev-next"
      REPO_DESC="sing-box beta版"
      ;;
    3) 
      REPO_URL="https://github.com/PuerNya/sing-box"
      BRANCH="building"
      REPO_DESC="sing-box 下游分支 (PuerNya)"
      ;;
    4) 
      REPO_URL="https://github.com/qjebbs/sing-box"
      BRANCH="main"
      REPO_DESC="sing-box 下游分支 (qjebbs)"
      ;;
    5) 
      REPO_URL="https://github.com/rnetx/sing-box"
      BRANCH="dev-next"
      REPO_DESC="sing-box 下游分支 (rnetx)"
      ;;
    *) 
      echo "无效选项."
      exit 1
      ;;
  esac
fi

echo "正在使用仓库: $REPO_URL, 分支: $BRANCH ($REPO_DESC), 构建目标平台: $GOOS"

ARCH_RAW=$(uname -m)
LATEST_VERSION=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases \
    | grep tag_name \
    | cut -d ":" -f2 \
    | sed 's/\"//g;s/\,//g;s/\ //g;s/v//' \
    | sort -V \
    | tail -n 1)

case "${ARCH_RAW}" in
    'x86_64')    ARCH='amd64';;
    'x86' | 'i686' | 'i386')     ARCH='386';;
    'aarch64' | 'arm64') ARCH='arm64';;
    'armv7l')   ARCH='armv7';;
    's390x')    ARCH='s390x';;
    *)          echo "Unsupported architecture: ${ARCH_RAW}"; exit 1;;
esac

if command -v go >/dev/null 2>&1; then
    echo "Go is already installed."
    go version
else
    echo "Go is not installed. Installing Go..."
    GO_VERSION="1.23.0"
    wget -q "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" -O go.tar.gz
    sudo tar -C /usr/local -xzf go.tar.gz
    CURRENT_SHELL=$(basename "$SHELL")

    case "$CURRENT_SHELL" in
        bash)
            CONFIG_FILE="$HOME/.bashrc"
            echo 'export GOROOT=/usr/local/go' >> "$CONFIG_FILE"
            echo 'export GOPATH=$HOME/go' >> "$CONFIG_FILE"
            echo 'export PATH=$PATH:$GOROOT/bin:$GOPATH/bin' >> "$CONFIG_FILE"
            ;;
        zsh)
            CONFIG_FILE="$HOME/.zshrc"
            echo 'export GOROOT=/usr/local/go' >> "$CONFIG_FILE"
            echo 'export GOPATH=$HOME/go' >> "$CONFIG_FILE"
            echo 'export PATH=$PATH:$GOROOT/bin:$GOPATH/bin' >> "$CONFIG_FILE"
            ;;
        fish)
            CONFIG_FILE="$HOME/.config/fish/config.fish"
            echo 'set -x GOROOT /usr/local/go' >> "$CONFIG_FILE"
            echo 'set -x GOPATH $HOME/go' >> "$CONFIG_FILE"
            echo 'set -x PATH $PATH $GOROOT/bin $GOPATH/bin' >> "$CONFIG_FILE"
            ;;
        *)
            echo "Unsupported shell: $CURRENT_SHELL"
            ;;
    esac
    source "$CONFIG_FILE"
    rm -f "go.tar.gz"
fi

apt install git -y
git clone "$REPO_URL" /tmp/sing-box && cd /tmp/sing-box
git checkout "$BRANCH"

# 构建 sing-box
OUTPUT_FILE="sing-box"
if [ -n "$OUTPUT_PATH" ]; then
    OUTPUT_FILE="${OUTPUT_PATH%/}/sing-box"
fi

GOOS=${GOOS} GOARCH=${ARCH} go build -ldflags "-X 'github.com/sagernet/sing-box/constant.Version=${LATEST_VERSION}'" \
    -tags "with_quic with_grpc with_dhcp with_wireguard with_ech with_utls with_reality_server with_acme with_clash_api with_v2ray_api with_gvisor" \
    -o "$OUTPUT_FILE" ./cmd/sing-box

chmod +x "$OUTPUT_FILE"

# 如果指定了输出路径，则跳过安装和服务配置
if [ -n "$OUTPUT_PATH" ]; then
    echo "The sing-box binary has been compiled and saved to $OUTPUT_FILE."
    exit 0
fi

# 继续安装和配置服务（如果未指定输出路径）
mkdir /etc/sing-box
echo "{}" > /etc/sing-box/config.json

cat <<EOF > /etc/systemd/system/sing-box.service
[Unit]
Description=sing-box service
Documentation=https://sing-box.sagernet.org
After=network.target nss-lookup.target

[Service]
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH
ExecStart=/usr/bin/sing-box -D /var/lib/sing-box -C /etc/sing-box run
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=10s
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable sing-box
systemctl start sing-box

sing-box version