#!/bin/bash

INSTALL_DIR="/usr/lib/jvm"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR" || { echo "无法切换到 $INSTALL_DIR 目录"; exit 1; }

declare -A java_versions
for version in 21 17 11 8; do
    version_number=$(curl -s "https://cdn.azul.com/zulu/bin/" | grep -oP "zulu${version}\.\d+\.\d+-ca-jdk${version}\.\d+\.\d+-linux_x64\.tar\.gz" | head -n 1)
    if [[ -n "$version_number" ]]; then
        java_versions[$version]="https://cdn.azul.com/zulu/bin/$version_number"
    fi
done

for version in "${!java_versions[@]}"; do
    if [[ -n "${java_versions[$version]}" ]]; then
        wget "${java_versions[$version]}" -qO "jdk${version}.tar.gz" && \
        tar -xzf "jdk${version}.tar.gz" && \
        rm -f "jdk${version}.tar.gz" && \
        mv "zulu${version}.*" "java${version}"
    fi
done

echo "JAVA 安装完成"
ls -a "$INSTALL_DIR"
echo "您可以使用 /usr/lib/jvm/java17/bin/java -jar server.jar 的方式启动您的服务器"
