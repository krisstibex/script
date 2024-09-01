#!/bin/bash
set -e -o pipefail

OUTPUT_PATH=""
REPO_URL=""
BRANCH=""
REPO_DESC=""
GOOS="linux"
WITH_TOR=false
INSTALL_NEW_GO=false
GO_VERSION="1.23.0"

if [[ $0 == "/proc/"* ]]; then
    script_name="sing-box.sh"
else
    script_name="$0"
fi

term_width=$(tput cols)
center_text() {
    local text="$1"
    local padding=$(( (term_width - ${#text}) / 2 ))
    printf "%*s\n" $((padding + ${#text})) "$text"
}
iecho() {
    local text="$1"
    printf "%*s%s\n" "$padding" "" "$text"
}
ascii_art=(
"      _                   _               "
"  ___(_)_ __   __ _      | |__   _____  __"
" / __| | '_ \\ / _\` |_____| '_ \\ / _ \\ \\/ /"
" \\__ \\ | | | | (_| |_____| |_) | (_) >  < "
" |___/_|_| |_|\\__, |     |_.__/ \\___/_/\\_\\"
"              |___/                       "
)
border=$(printf '%*s' "$term_width" '' | tr ' ' '#')
menu=(
  "请选择要使用的仓库和分支:"
  "1) sing-box 稳定版 (https://github.com/SagerNet/sing-box, 分支: main)"
  "2) sing-box beta版 (https://github.com/SagerNet/sing-box, 分支: dev-next)"
  "3) sing-box 下游分支 (PuerNya) (https://github.com/PuerNya/sing-box, 分支: building)"
  "4) sing-box 下游分支 (qjebbs) (https://github.com/qjebbs/sing-box, 分支: main)"
  "5) sing-box 下游分支 (rnetx) (https://github.com/rnetx/sing-box, 分支: dev-next)"
)
max_width=0
for line in "${menu[@]}"; do
  (( ${#line} > max_width )) && max_width=${#line}
done
padding=$(( (term_width - max_width) / 2 ))

while getopts "o:a:d:v:" opt; do
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
    d) GOOS="$OPTARG";;
    v) GO_VERSION="$OPTARG";;
    *) echo "Usage: $script_name [-o output_path] [-a repo name] [-d go os] [-v go version]" >&2; exit 1;;
  esac
done

shift $((OPTIND -1))

for arg in "$@"; do
  case $arg in
    tor) WITH_TOR=true;;
    go) INSTALL_NEW_GO=true;;
    help) echo "Usage: $script_name [-o output_path] [-a repo name] [-d go os] [-v go version]" >&2; exit 1;;
  esac
done

if [ -z "$REPO_URL" ]; then
  echo "$border"
  echo "$border"
  for line in "${ascii_art[@]}"; do
    center_text "$line"
  done
  echo "$border"
  echo "$border"
  for line in "${menu[@]}"; do
  printf "%*s%s\n" "$padding" "" "$line"
  done
  read -p "$(printf "%*s" "$padding")请输入选项 (1-5): " choice

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
      iecho "无效选项."
      exit 1
      ;;
  esac
fi

iecho "正在使用仓库: $REPO_URL, 分支: $BRANCH ($REPO_DESC), 构建目标平台: $GOOS"

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
    iecho "Go 已安装"
    go version
else
    if [ "$INSTALL_NEW_GO" = true ]; then
        iecho "Go 未安装 正在安装..."
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
                echo "不支持的 shell: $CURRENT_SHELL"
                ;;
        esac
        source "$CONFIG_FILE"
        rm -f "go.tar.gz"
    else
        iecho "Go 未安装 使用 apt 安装..."
        sudo apt update
        sudo apt install -y golang
    fi
fi

apt install git -y
git clone "$REPO_URL" /tmp/sing-box && cd /tmp/sing-box
git checkout "$BRANCH"

OUTPUT_FILE="sing-box"
if [ -n "$OUTPUT_PATH" ]; then
    OUTPUT_FILE="${OUTPUT_PATH%/}/sing-box"
fi

TAGS="with_quic with_grpc with_dhcp with_wireguard with_ech with_utls with_reality_server with_acme with_clash_api with_v2ray_api with_gvisor"
if [ "$WITH_TOR" = true ]; then
    TAGS="$TAGS with_embedded_tor"
fi

GOOS=${GOOS} GOARCH=${ARCH} go build -ldflags "-X 'github.com/sagernet/sing-box/constant.Version=${LATEST_VERSION}'" \
    -tags "$TAGS" \
    -o "$OUTPUT_FILE" ./cmd/sing-box

chmod +x "$OUTPUT_FILE"

if [ -n "$OUTPUT_PATH" ]; then
    echo "The sing-box binary has been compiled and saved to $OUTPUT_FILE."
    exit 0
fi

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
