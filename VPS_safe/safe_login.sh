#!/bin/bash

echo "========== SSH 安全配置脚本 =========="

# 1. 修改 SSH 远程登录端口
echo "步骤 1: 修改 SSH 远程登录端口"
read -p "请输入新的 SSH 端口（直接回车自动生成 10000-65535 范围的端口）： " new_port
if [[ -z "$new_port" ]]; then
  new_port=$((RANDOM % 55536 + 10000))
  echo "自动生成的 SSH 端口为: $new_port"
elif ! [[ $new_port =~ ^[0-9]+$ ]]; then
  echo "端口号无效，请输入一个有效的数字！"
  exit 1
fi

# 替换现有的 Port 设置
sudo sed -i "s/^Port .*/Port $new_port/" /etc/ssh/sshd_config

# 如果没有找到 Port 行，添加新的 Port 行
if ! grep -q "^Port" /etc/ssh/sshd_config; then
    echo "Port $new_port" | sudo tee -a /etc/ssh/sshd_config
fi

echo "SSH 端口已修改为 $new_port"
echo "------------------------------------"

# 2. 创建新用户，并禁用 root SSH 登录
echo "步骤 2: 创建新用户，并禁用 root 远程登录"
read -p "请输入新用户名： " new_user
if id "$new_user" &>/dev/null; then
  echo "用户 $new_user 已存在。"
else
  sudo adduser --disabled-password --gecos "" $new_user
  echo "用户 $new_user 创建成功（无需密码登录）。"
fi
sudo usermod -aG sudo $new_user
sudo sed -i "s/PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
echo "已禁用 root 用户的 SSH 远程登录"
echo "------------------------------------"

# 3. 启用 RSA 密钥验证，并禁用密码验证
echo "步骤 3: 启用 RSA 密钥验证，并禁用密码验证"
rsa_dir="/home/$new_user/.ssh"
rsa_path="$rsa_dir/id_rsa"
if [ ! -d "$rsa_dir" ]; then
  sudo mkdir -p "$rsa_dir"
  sudo chown $new_user:$new_user "$rsa_dir"
  sudo chmod 700 "$rsa_dir"
fi

# 生成密钥对
sudo -u $new_user ssh-keygen -t rsa -b 4096 -f "$rsa_path" -N "" -q
sudo chmod 600 "$rsa_path"  # 设置私钥权限

# 将公钥添加到 authorized_keys
sudo -u $new_user cat "$rsa_path.pub" >> "$rsa_dir/authorized_keys"
sudo chmod 600 "$rsa_dir/authorized_keys"

# 更新 sshd 配置以启用密钥验证并禁用密码验证
sudo sed -i "s/#PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
sudo sed -i "s/#PubkeyAuthentication yes/PubkeyAuthentication yes/" /etc/ssh/sshd_config
echo "RSA 密钥已生成，密码验证已禁用，密钥验证已启用。"
echo "------------------------------------"

# 显示生成的 RSA 私钥
echo "下面是生成的 RSA 私钥，请妥善保存："
sudo cat "$rsa_path"
echo "公钥已存储在 $rsa_dir/id_rsa.pub"
echo "------------------------------------"

# 4. 重启 SSH 服务
echo "正在重启 SSH 服务以应用更改..."
sudo systemctl restart ssh
sudo systemctl status ssh
echo "SSH 服务已重启。"

# 5. 获取服务器公网 IP
echo "正在获取服务器的公网 IP..."
server_ip=$(curl -4 -s --max-time 5 ip.sb)
if [[ -z "$server_ip" ]]; then
  echo "无法通过 IPv4 获取 IP，尝试 IPv6..."
  server_ip=$(curl -6 -s ip.sb)
  if [[ -z "$server_ip" ]]; then
    server_ip="无法获取 IP，请手动检查"
  fi
fi

# 6. 打印连接信息
echo "========== 连接信息 =========="
echo "用户名: $new_user"
echo "SSH 端口: $new_port"
echo "服务器 IP: $server_ip"
echo "私钥内容如下，请妥善保存："
sudo cat "$rsa_path"
echo
echo "请使用以下命令连接到服务器："
echo "ssh -i /path/to/your_private_key -p $new_port $new_user@$server_ip"
echo "注意：/path/to/your_private_key 是本地存放私钥的路径，请替换为实际路径。"
echo "------------------------------------"

echo "========== 所有步骤已完成 =========="
echo "请确保已将公钥添加到需要访问的服务器的 ~/.ssh/authorized_keys 中，以便新用户能够使用密钥登录。"
