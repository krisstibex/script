#!/bin/bash

INSTALL_DIR="/usr/lib/jvm"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR" || { echo "无法切换到 $INSTALL_DIR 目录"; exit 1; }

# 检测系统架构和 C 库类型
ARCH=$(uname -m)
LIBC_TYPE=""

# 检测 C 库类型
if ldd --version 2>&1 | grep -q musl; then
    LIBC_TYPE="musl"
else
    LIBC_TYPE="glibc"
fi

# 设置架构名称
if [[ "$ARCH" == "x86_64" ]]; then
    ARCH_NAME="x64"
elif [[ "$ARCH" == "aarch64" ]]; then
    ARCH_NAME="aarch64"
else
    echo "不支持的架构: $ARCH"
    exit 1
fi

# 处理参数
PACKAGE_TYPE="${1:-jre}" # 默认为 jre
VERSION_PARAM="$2" # -v
VERSIONS="${3:-@}" # 默认安装最新版本

if [[ "$PACKAGE_TYPE" != "jdk" && "$PACKAGE_TYPE" != "jre" ]]; then
    echo "用法: bash script.sh [jdk|jre] -v <8,11,17,21|@>"
    exit 1
fi

if [[ "$VERSION_PARAM" != "-v" ]]; then
    echo "请使用 -v 指定版本号"
    exit 1
fi

IFS=',' read -ra VERSION_ARRAY <<< "$VERSIONS"

declare -A java_versions
for version in "${VERSION_ARRAY[@]}"; do
    # 构建版本模式，如果版本为 @ 则选择最新版本
    if [[ "$version" == "@" ]]; then
        version_pattern="${PACKAGE_TYPE}\d+\.\d+\.\d+-ca-${PACKAGE_TYPE}\d+\.\d+\.\d+-linux_${ARCH_NAME}\.tar\.gz"
        [[ "$LIBC_TYPE" == "musl" ]] && version_pattern="${PACKAGE_TYPE}\d+\.\d+\.\d+-ca-${PACKAGE_TYPE}\d+\.\d+\.\d+-linux_musl_${ARCH_NAME}\.tar\.gz"
    else
        version_pattern="${PACKAGE_TYPE}${version}\.\d+\.\d+-ca-${PACKAGE_TYPE}${version}\.\d+\.\d+-linux_${ARCH_NAME}\.tar\.gz"
        [[ "$LIBC_TYPE" == "musl" ]] && version_pattern="${PACKAGE_TYPE}${version}\.\d+\.\d+-ca-${PACKAGE_TYPE}${version}\.\d+\.\d+-linux_musl_${ARCH_NAME}\.tar\.gz"
    fi

    # 查找匹配的版本
    version_number=$(curl -s "https://cdn.azul.com/zulu/bin/" | grep -oP "$version_pattern" | head -n 1)
    if [[ -n "$version_number" ]]; then
        java_versions[$version]="https://cdn.azul.com/zulu/bin/$version_number"
    else
        echo "无法找到 ${PACKAGE_TYPE}${version} 的匹配版本"
    fi
done

# 下载并安装指定版本
for version in "${!java_versions[@]}"; do
    if [[ -n "${java_versions[$version]}" ]]; then
        wget "${java_versions[$version]}" -qO "${PACKAGE_TYPE}${version}.tar.gz" && \
        tar -xzf "${PACKAGE_TYPE}${version}.tar.gz" && \
        rm -f "${PACKAGE_TYPE}${version}.tar.gz" && \
        mv "${PACKAGE_TYPE}${version}.*" "${PACKAGE_TYPE}${version}"
        echo "${PACKAGE_TYPE}${version} 已安装"
    fi
done

echo "JAVA 安装完成"
ls -a "$INSTALL_DIR"
echo "您可以使用 /usr/lib/jvm/${PACKAGE_TYPE}17/bin/java -jar server.jar 的方式启动您的服务器"
