@echo off
setlocal

REM 设置工作目录
set "INSTALL_DIR=C:\JDK"
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

cd /d "%INSTALL_DIR%"

echo 开始下载最新版本的 JAVA (Azul JDK)

REM 定义 JDK 版本下载链接
set "JDK_URL_21="
set "JDK_URL_17="
set "JDK_URL_11="
set "JDK_URL_8="

for %%V in (21 17 11 8) do (
    powershell -Command "(Invoke-WebRequest -Uri 'https://cdn.azul.com/zulu/bin/' -UseBasicParsing).Content" > temp.txt
    findstr /r /c:"zulu%%V\.[0-9]*\.[0-9]*-ca-jdk%%V\.[0-9]*\.[0-9]*-win_x64.zip" temp.txt > temp_link.txt
    set /p "JDK_URL_%%V=" < temp_link.txt
    del temp.txt
    del temp_link.txt
)

REM 下载和解压 JDK
for %%V in (21 17 11 8) do (
    if defined JDK_URL_%%V (
        powershell -Command "Invoke-WebRequest -Uri '%JDK_URL_%%V%' -OutFile 'jdk%%V.zip'"
        powershell -Command "Expand-Archive -Path 'jdk%%V.zip' -DestinationPath 'java%%V'"
        del "jdk%%V.zip"
    )
)

echo JAVA 安装完成
dir "%INSTALL_DIR%"

echo 您可以使用 C:\JDK\java17\bin\java -jar server.jar 的方式启动
