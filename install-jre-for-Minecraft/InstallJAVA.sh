#!/bin/bash

cd /root
echo "开始下载JAVA(Azul jdk)"
wget https://cdn.azul.com/zulu/bin/zulu21.34.19-ca-jdk21.0.3-linux_x64.tar.gz
wget https://cdn.azul.com/zulu/bin/zulu17.50.19-ca-jdk17.0.11-linux_x64.tar.gz
wget https://cdn.azul.com/zulu/bin/zulu11.72.19-ca-jdk11.0.23-linux_x64.tar.gz
wget https://cdn.azul.com/zulu/bin/zulu8.78.0.19-ca-jdk8.0.412-linux_x64.tar.gz

echo "下载完成 开始解压"
tar -xzvf zulu21.34.19-ca-jdk21.0.3-linux_x64.tar.gz > /dev/null 2>&1
tar -xzvf zulu17.50.19-ca-jdk17.0.11-linux_x64.tar.gz > /dev/null 2>&1
tar -xzvf zulu11.72.19-ca-jdk11.0.23-linux_x64.tar.gz > /dev/null 2>&1
tar -xzvf zulu8.78.0.19-ca-jdk8.0.412-linux_x64.tar.gz > /dev/null 2>&1
rm -f zulu*.gz
mv zulu21.34.19-ca-jdk21.0.3-linux_x64 java21
mv zulu17.50.19-ca-jdk17.0.11-linux_x64 java17
mv zulu11.72.19-ca-jdk11.0.23-linux_x64 java11
mv zulu8.78.0.19-ca-jdk8.0.412-linux_x64 java8

echo "JAVA安装完成"
ls -a
echo 您可以使用/root/java17/bin/java -jar server.jar 的方式启动您的服务器
