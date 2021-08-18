#!/bin/bash

echo "####################"
echo "=== Hostname Set ==="
echo "####################"
read -p "hostname: " host_name
hostnamectl set-hostname $host_name
hostnamectl
echo "===check hostname complete==="
echo "hostname setting complete" >> check.txt

echo "####################"
echo "=== Network Devices ==="
echo "####################"
ip a | grep '^[0-9]' | awk '{print $1" "$2}' | grep -v -e 'lo' -e 'v' -e 't'
read -p "interface: " net_name
read -p "your ip(ex:192.168.122.10/24): " net_ip
read -p "gateway: " net_gw
read -p "dns: " net_dns

if [[ -z $net_name ]] || [[ -z $net_ip ]] || [[ -z $net_gw ]] || [[ -z $net_dns ]]; then
  echo "wrong network Please restart this"
  exit;
fi


nmcli con mod $net_name ifname $net_name ipv4.address $net_ip ipv4.gateway $net_gw ipv4.dns $net_dns ipv4.method manual connection.autoconnect yes
nmcli con up $net_name
ifdown $net_name
ifup $net_name

echo "=== check network==="
ip a show $net_name

chk_ping=$(ping 8.8.8.8 -c 4 | grep -e packets | awk '{print $4}')

if [[ $chk_ping -eq 0 ]]; then
  echo "===please check network==="
  echo "network setting not complete" >> check.txt
  exit
else
  echo "===check network complete==="
  echo "network setting complete" >> check.txt
fi

##centos-7-x86_64-Minimal-1908.iso 


echo "#######################"
echo "=== package installation ==="
echo "#######################"

yum -y update
yum -y install epel-release rsync wget vim psmisc net-tools lsof chrony
echo "===package setting complete==="
echo "package setting complete" >> check.txt


echo "##################"
echo "=== language set ==="
echo "##################"
localectl set-locale LANG=ko_KR.UTF-8
locale | grep ko_KR
echo "===language setting complete==="
echo "language setting complete" >> check.txt

echo "##################"
echo "=== TimeZone ==="
echo "##################"

tz=$(timedatectl | grep -e Asia | awk '{print  $3}')

if [[ $tz == 'Asia/Seoul' ]]; then
  echo "===timezone already setting==="
  echo "timezone already setting" >> check.txt
else
  timedatectl set-timezone Asia/Seoul
  echo "===timezone setting complete===" 
  echo "timezone setting complete" >> check.txt
fi


echo "##############"
echo "=== NTP SET ==="
echo "###############"  

ip=""
netmask=""
conf=/etc/chrony.conf

systemctl start chronyd
systemctl enable chronyd

# 서버 주소 변경
sed -i "s/^server/#server/g" $conf
sed -i "/^#server 3/ a \server time.bora.net iburst" $conf


# 서비스 재시작
echo "===systemctl restart chronyd==="
systemctl restart chronyd

# 포트 추가
echo "===firewall-cmd open ntp==="
firewall-cmd --add-service=ntp --permanent
firewall-cmd --reload

echo "===check ntp==="
chronyc sources

ntpact=$(systemctl is-active chronyd)

if [[ $ntpact == 'active' ]]; then
  echo "===ntp setting complete==="
  echo "ntp setting complete" >> check.txt
else
  echo "===ntp setting not complete==="
  echo "ntp setting not complete" >> check.txt
fi


echo "##############"
echo "=== SSH SET ==="
echo "###############"


conf_path=/etc/ssh/sshd_config


# 환경설정 파일 백업
cp $conf_path ${conf_path}.bak.$(date +%Y%m%d)


  # Port 변경
  read -p "Please input port: " port
  exist_conf=$(cat $conf_path | grep -e '^#Port' -e '^Port')
  sed -i "s/$exist_conf/Port $port/g" $conf_path

  # PermitRootLogin 변경
  read -p "Please input PermitRootLogin yes or no: " rootyn
  exist_conf=$(cat $conf_path | grep -e '^#PermitRootLogin' -e '^PermitRootLogin')
  sed -i "s/$exist_conf/PermitRootLogin $rootyn/g" $conf_path


  # PasswordAuthentication 변경
  read -p "Please input PasswordAuthentication yes or no: " pwyn
  exist_conf=$(cat $conf_path | grep -e '^PasswordAuthentication')
  #echo $exist_conf
  #echo $pwyn
  sed -i "s/$exist_conf/PasswordAuthentication $pwyn/g" $conf_path


  # PubkeyAuthentication 변경
  read -p "Please input PubkeyAuthentication yes or no: " keyyn
  exist_conf=$(cat $conf_path | grep -e '^#PubkeyAuthentication' -e '^PubkeyAuthentication')
  sed -i "s/$exist_conf/PubkeyAuthentication $keyyn/g" $conf_path

  echo "Restart sshd"
  systemctl restart sshd

  echo "===ssh setting complete==="
  echo "ssh setting complete" >> check.txt


echo "###################################"
echo "============ Host Set  ============"
echo "if you want to out loop, please input word 'exit'"
echo "###################################"

while true
do
  read -p "hosts ip/name : " hosts_ip_name
 
  if [[ $hosts_ip_name == 'exit' ]]; then
    break
  fi
  echo $hosts_ip_name >> /etc/hosts
done

  echo "===hosts setting complete==="
  echo "hosts setting complete" >> check.txt










