#!/bin/bash

INSTALL_DIR="/usr/lib/jvm"
mkdir -p "$INSTALL_DIR"

cd "$INSTALL_DIR" || { echo "无法切换到 $INSTALL_DIR 目录"; exit 1; }

declare -A java_versions=(
    [21]="https://cdn.azul.com/zulu/bin/zulu21.38.21-ca-jdk21.0.5-linux_x64.tar.gz"
    [17]="https://cdn.azul.com/zulu/bin/zulu17.54.21-ca-jdk17.0.13-linux_x64.tar.gz"
    [11]="https://cdn.azul.com/zulu/bin/zulu11.76.21-ca-jdk11.0.25-linux_x64.tar.gz"
    [8]="https://cdn.azul.com/zulu/bin/zulu8.82.0.21-ca-jdk8.0.432-linux_x64.tar.gz"
)

for version in "${!java_versions[@]}"; do
    wget "${java_versions[$version]}" -qO "jdk${version}.tar.gz"
done

for version in 21 17 11 8; do
    tar -xzf "jdk${version}.tar.gz"
    rm -f "jdk${version}.tar.gz"
    mv "zulu${version}.*" "java${version}"
done

echo "JAVA 安装完成"
ls -a "$INSTALL_DIR"
echo "您可以使用 /usr/lib/jvm/java17/bin/java -jar server.jar 的方式启动您的服务器"
