#!/bin/bash

INSTALL_DIR="/usr/lib/jvm"
mkdir -p "$INSTALL_DIR"

cd "$INSTALL_DIR" || { echo "无法切换到 $INSTALL_DIR 目录"; exit 1; }

declare -A java_versions=(
    [21]="https://cdn.azul.com/zulu/bin/zulu21.34.19-ca-jdk21.0.3-linux_x64.tar.gz"
    [17]="https://cdn.azul.com/zulu/bin/zulu17.50.19-ca-jdk17.0.11-linux_x64.tar.gz"
    [11]="https://cdn.azul.com/zulu/bin/zulu11.72.19-ca-jdk11.0.23-linux_x64.tar.gz"
    [8]="https://cdn.azul.com/zulu/bin/zulu8.78.0.19-ca-jdk8.0.412-linux_x64.tar.gz"
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
