#!/bin/bash

INSTALL_DIR="/usr/lib/jvm"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR" || { echo "无法切换到 $INSTALL_DIR 目录"; exit 1; }

# 预定义每个 Java 版本的基础下载链接
java8="zulu8.72.0.17-ca-jdk8.0.382"
java11="zulu11.64.19-ca-jdk11.0.20"
java17="zulu17.44.15-ca-jdk17.0.8"
java21="zulu21.38.21-ca-jdk21.0.5"

# 检测系统架构和 C 库类型
ARCH=$(uname -m)
LIBC_TYPE=""

if ldd --version 2>&1 | grep -q musl; then
    LIBC_TYPE="musl"
else
    LIBC_TYPE="glibc"
fi

# 设置架构名称
case "$ARCH" in
    x86_64)
        ARCH_NAME="x64"
        ;;
    aarch64)
        ARCH_NAME="aarch64"
        ;;
    i686)
        ARCH_NAME="i686"
        ;;
    *)
        echo "不支持的架构: $ARCH"
        exit 1
        ;;
esac

# 处理参数，默认行为为 jdk 和最新版
PACKAGE_TYPE="jdk"
VERSION_PARAM="@"

while [[ $# -gt 0 ]]; do
    case "$1" in
        jdk|jre)
            PACKAGE_TYPE="$1"
            shift
            ;;
        -v)
            VERSION_PARAM="$2"
            shift 2
            ;;
        *)
            echo "用法: bash script.sh [jdk|jre] -v <8,11,17,21|@>"
            exit 1
            ;;
    esac
done

IFS=',' read -ra VERSION_ARRAY <<< "$VERSION_PARAM"

declare -A java_versions
for version in "${VERSION_ARRAY[@]}"; do
    # 根据版本号设置下载链接基础部分
    case $version in
        8) base_url="$java8";;
        11) base_url="$java11";;
        17) base_url="$java17";;
        21) base_url="$java21";;
        @) base_url="$java21";; # 默认最新为 21
        *) echo "不支持的版本: $version"; continue;;
    esac

    # 根据 C 库类型和架构设置下载链接的完整路径
    if [[ "$LIBC_TYPE" == "musl" ]]; then
        download_url="https://cdn.azul.com/zulu/bin/${base_url}-linux_musl_${ARCH_NAME}.tar.gz"
    else
        download_url="https://cdn.azul.com/zulu/bin/${base_url}-linux_${ARCH_NAME}.tar.gz"
    fi

    java_versions[$version]="$download_url"
done

# 下载并安装指定版本
for version in "${!java_versions[@]}"; do
    if [[ -n "${java_versions[$version]}" ]]; then
        wget "${java_versions[$version]}" -qO "${PACKAGE_TYPE}${version}.tar.gz" && \
        tar -xzf "${PACKAGE_TYPE}${version}.tar.gz" && \
        rm -f "${PACKAGE_TYPE}${version}.tar.gz" && \
        mv "${PACKAGE_TYPE}${version}.*" "${PACKAGE_TYPE}${version}"
        echo "${PACKAGE_TYPE}${version} 已安装"
    else
        echo "无法找到 ${PACKAGE_TYPE}${version} 的下载链接"
    fi
done

echo "JAVA 安装完成"
ls -a "$INSTALL_DIR"
echo "您可以使用 /usr/lib/jvm/${PACKAGE_TYPE}17/bin/java -jar server.jar 的方式启动您的服务器"
