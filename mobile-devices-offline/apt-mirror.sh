#!/bin/bash

# Условие для автомонтирования носителя
if [ ! -d /mnt/mirror ]
  then mkdir /mnt/mirror
       findfs LABEL=MIRROR > /dev/null
       if [ 0 = `echo $?` ]
          then echo -e "### Монтирование накопителя ###\n"
               mount LABEL=MIRROR /mnt/mirror
               mkdir /mnt/mirror/repo/
          else echo -e "### Носитель отформотирован неверно, метки \"MIRROR\" не существует ###\n"
               exit 1
       fi
  else findfs LABEL=MIRROR > /dev/null
       if [ 0 = `echo $?` ]
       then echo -e "### Монтирование накопителя ###\n"
               mount LABEL=MIRROR /mnt/mirror
               mkdir /mnt/mirror/repo/
       else echo -e "### Носитель отформотирован неверно, метки \"MIRROR\" не существует ###\n"
            exit 1
fi

# Создание зеркального репозитория на носителе
echo -e "### Установка пакета для зеркалирования репозитория ###\n"
apt install apt-mirror &> /dev/null

echo -e "### Настройка зеркалирования ###\n"
mv /etc/apt/mirror.list /etc/apt/mirror.list.bak
cat >> /etc/apt/mirror.list << EOL
############# config ##################
set base_path /mnt/mirror/repo
set nthreads     20
set _tilde 0
#
# set mirror_path  \$base_path/mirror
# set skel_path    \$base_path/skel
# set var_path     \$base_path/var
# set cleanscript \$var_path/clean.sh
# set defaultarch  <running host architecture>
# set postmirror_script \$var_path/postmirror.sh
# set run_postmirror 0
#
############# end config ##############

############# repository ##############
deb [arch=amd64] http://spb99pcoapp09.gazprom-neft.local/repos/buster/debian-security/ 1.7_x86-64 main
deb [arch=amd64] http://spb99pcoapp09.gazprom-neft.local/repos/buster/third-party/ 1.7_x86-64 main
clean deb [arch=amd64] http://spb99pcoapp09.gazprom-neft.local/repos/buster/debian-security/
clean deb [arch=amd64] http://spb99pcoapp09.gazprom-neft.local/repos/buster/third-party/
EOL

echo -e "### Запуск клонирования репозиториев ###\n"
/usr/bin/apt-mirror

# Скачивание сценариев обновления на носитель
wget -O - "http://spb99pcoapp09.gazprom-neft.local/repos/gpg.key" | apt-key add -

if ! grep -q "BEGIN CERTIFICATE" "/root/https-cert.pem"; then
	cat >> /root/https-cert.pem << EOL
-----BEGIN CERTIFICATE-----
MIIDHjCCAgagAwIBAgIUWrHdFmvqGLJcNZv6E12OZ39sXcwwDQYJKoZIhvcNAQEL
BQAwKzEpMCcGA1UEAwwgU1BCOTlQQ09BUFAwOS5nYXpwcm9tLW5lZnQubG9jYWww
HhcNMjEwNjA1MDg1MTE3WhcNMzEwNjAzMDg1MTE3WjArMSkwJwYDVQQDDCBTUEI5
OVBDT0FQUDA5LmdhenByb20tbmVmdC5sb2NhbDCCASIwDQYJKoZIhvcNAQEBBQAD
ggEPADCCAQoCggEBAKeIE7H/0EoBc5we0sS2YOzMGz/yAdjhzwpOwafZsUzDCN3o
FmHsLYn//apAbpuwS1K8SZwBEj9eHJsYhqRy81LqZOmWDNB8eYDTL/xyYFwcPOYm
6PCe9kAYyDNXZGtxpxA4VRSlqJIsexfq0jkueDdrbYqaRJV/lRBrZdgY5NXpFPpe
8eJOYu+TEJ2FEQgqCNETRpPkhYuD+0rDpONK28Fd1jj5CiBAzO1YpmkPbTlqcN4L
9FBlEq69gB0X9EOShQSUYwCsCyddtMq7d6M87IrfD6dTCosy2godezCceNzVsmy0
rtwGlkyImGFm/Iie+9C4FDx0KERnS/gkMv+u/vMCAwEAAaM6MDgwCQYDVR0TBAIw
ADArBgNVHREEJDAigiBTUEI5OVBDT0FQUDA5LmdhenByb20tbmVmdC5sb2NhbDAN
BgkqhkiG9w0BAQsFAAOCAQEAckHjN0RSwew8cx4tg9eOfTzWunxEXOfxJ2uBzWp3
1Az7b6qmEO1QH621OUeegQEYVM9MXsa+m/B7IywfbE0LJkt/3LY1EgcTs4P980Ku
XztnGBpYahWfUBEsxQ7MmsGKeDSM1jYYktuEkh0pOWXm8niWxfaelKeBUSQE4hkV
4hBvqilmqreTlstnV3lWpd8zX+Rptg6JyiKA/BUSzZDzB59a5ROaZtbyigowHTqL
uFLfnMySTFkzMwekb7cky2NteyHp7nG8mpa4p+hY8BB24kkYWDwdekeXfLx8lMyJ
9om4VE7FZ5MstCoITce8St90JUjdTs13hXGCN9KUgUh3Nw==
-----END CERTIFICATE-----
EOL
	echo "[http]" > /root/.gitconfig
	echo "    sslCAinfo = /root/https-cert.pem" >> /root/.gitconfig
fi

echo -e "### Скачивание ролей обновления ###\n"
cd /mnt/mirror
git init &> /dev/null
git clone https://spb99pcoapp09.gazprom-neft.local/git/remediations-roles &> /dev/null

# Создание сценария запуска обновлений
echo -e "### Генерация скрипта запуска обновлений (/mnt/mirror/update.sh) ###\n"
     cat >> /mnt/mirror/update.sh << EOL
#!/bin/bash

# Переменные
mountpoint=\$(df -Th | grep `findfs LABEL=MIRROR` | cut -d'%' -f2 | sed 's/^\s*//g')
sources="/etc/apt/sources.list"

# Подготовка пакетного менеджера
echo -e "### Настройка репозиториев ###\n"

mv \$sources \$sources.bak
echo # KSPD REPO BEGIN > /etc/apt/sources.list
echo # deb http://spb99pcoapp09.gazprom-neft.local/1.7_x86-64/repository-main/ 1.7_x86-64 main contrib non-free >> \$sources
echo # deb http://spb99pcoapp09.gazprom-neft.local/1.7_x86-64/repository-update/ 1.7_x86-64 main contrib non-free >> \$sources
echo # deb http://spb99pcoapp09.gazprom-neft.local/1.7_x86-64/repository-base/ 1.7_x86-64 main contrib non-free >> \$sources
echo # deb http://spb99pcoapp09.gazprom-neft.local/1.7_x86-64/repository-extended/ 1.7_x86-64 main contrib non-free >> \$sources
echo # deb [arch=amd64] http://spb99pcoapp09.gazprom-neft.local/repos/buster/debian-security/ 1.7_x86-64 main >> \$sources
echo # deb [arch=amd64] http://spb99pcoapp09.gazprom-neft.local/repos/buster/third-party/ 1.7_x86-64 main >> \$sources
echo # KSPD REPO END >> \$sources
echo >> \$sources
echo # ASTRA-LINUX REPO BEGIN >> \$sources
echo deb https://download.astralinux.ru/astra/stable/1.7_x86-64/repository-main/ 1.7_x86-64 main contrib non-free >> \$sources
echo deb https://download.astralinux.ru/astra/stable/1.7_x86-64/repository-update/ 1.7_x86-64 main contrib non-free >> \$sources
echo deb https://download.astralinux.ru/astra/stable/1.7_x86-64/repository-base/ 1.7_x86-64 main contrib non-free >> \$sources
echo deb https://download.astralinux.ru/astra/stable/1.7_x86-64/repository-extended/ 1.7_x86-64 main contrib non-free >> \$sources
echo # ASTRA-LINUX REPO END >> \$sources
echo >> \$sources
echo # LOCAL REPO BEGIN >> \$sources
echo deb file://\$mountpoint/repo/mirror/spb99pcoapp09.gazprom-neft.local/repos/buster/debian-security/ 1.7_x86-64 main >> \$sources
echo deb file://\$mountpoint/repo/mirror/spb99pcoapp09.gazprom-neft.local/repos/buster/third-party/ 1.7_x86-64 main >> \$sources
echo # LOCAL REPO END >> \$sources

apt update &> /dev/null

# Подготовка системы к запуску обновлений
echo -e "### Установка необходимых пакетов ###\n"
apt install -y git &> /dev/null
apt install -y ansible &> /dev/null
apt install -y python &> /dev/null
apt install -y openssh-server &> /dev/null
apt install -y dnsutils &> /dev/null
cd \$mountpoint/remediations-roles

# Обновление системы
echo -e "### Запуск обновлений ###\n"
ansible-playbook ./mobile-device-offline.yml --connection=local -l localhost
echo -e "### Обновление выполненно успешно ###\n"
EOL

echo -e "### Локальный репозиторий готов к использованию ###\n"