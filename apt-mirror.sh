#!/bin/bash

# Colors
DEF='\033[0;39m'
RED='\033[0;31m'
YELLOW='\033[0;33m'


# Условие для автомонтирования носителя
if [ ! -d /mnt/mirror ]
  then mkdir /mnt/mirror
       findfs LABEL=MIRROR > /dev/null
       if [ 0 = `echo $?` ]
          then echo -e "\n${YELLOW}### МОНТИРОВАНИЕ НАКОПИТЕЛЯ ###\n"
               mount LABEL=MIRROR /mnt/mirror &> /dev/null
               if [ 0 = `echo $?` ]
                  then mount -o remount LABEL=MIRROR /mnt/mirror
               fi
               mkdir /mnt/mirror/repo/
          else echo -e "\n${RED}### НОСИТЕЛЬ ОТФОРМАТИРОВАН НЕВЕРНО, МЕТКИ \"MIRROR\" НЕ СУЩЕСТВУЕТ ###\n"
               exit 1
       fi
  else findfs LABEL=MIRROR > /dev/null
       if [ 0 = `echo $?` ]
       then echo -e "\n${YELLOW}### МОНТИРОВАНИЕ НАКОПИТЕЛЯ ###\n"
               mount LABEL=MIRROR /mnt/mirror &> /dev/null
               if [ 0 = `echo $?` ]
                  then mount -o remount LABEL=MIRROR /mnt/mirror
               fi
               mkdir /mnt/mirror/repo/
       else echo -e "\n### НОСИТЕЛЬ ОТФОРМАТИРОВАН НЕВЕРНО, МЕТКИ \"MIRROR\" НЕ СУЩЕСТВУЕТ ###\n"
            exit 1
        fi
fi

# Создание зеркального репозитория на носителе
echo -e "\n${YELLOW}### УСТАНОВКА ПАКЕТА ДЛЯ ЗЕРКАЛИРОВАНИЯ РЕПОЗИТОРИЯ ###\n"
apt install apt-mirror &> /dev/null

echo -e "\n${YELLOW}### НАСТРОЙКА ЗЕРКАЛИРОВАНИЯ ###\n"
mv /etc/apt/mirror.list /etc/apt/mirror.list.bak
cat > /etc/apt/mirror.list << EOL
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

echo -e "\n${YELLOW}### ЗАПУСК КЛОНИРОВАНИЯ РЕПОЗИТОРИЕВ ###\n"
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

echo -e "\n${YELLOW}### СКАЧИВАНИЕ РОЛЕЙ ОБНОВЛЕНИЯ ###\n"
cd /mnt/mirror
git init &> /dev/null
git clone https://spb99pcoapp09.gazprom-neft.local/git/remediations-roles &> /dev/null

# Создание сценария запуска обновлений
echo -e "\n${YELLOW}### ГЕНЕРАЦИЯ СКРИПРТА ЗАПУСКА ОБНОВЛЕНИЙ ${RED}(/mnt/mirror/update.sh) ${DEF}###\n"
     cat > /mnt/mirror/update.sh << EOL
#!/bin/bash

# Variables
MOUNTPOINT=\$(lsblk -P | grep MIRROR | cut -d' ' -f7 | sed -n 's/\(MOUNTPOINT=\"\)\(.*\)\(\"\)/\2/p')
SOURCES="/etc/apt/sources.list"
LOG="\$MOUNTPOINT/update.log"

# Colors
DEF='\033[0;39m'
RED='\033[0;31m'
YELLOW='\033[0;33m'

# Package manager configuration
echo -e "\n\${YELLOW}### НАСТРОЙКА РЕПОЗИТОРИЕВ ###\n" | tee \$LOG

grep "deb file://\$MOUNTPOINT" \$SOURCES &> /dev/null
if [ 0 != `echo \$\?` ]
   then
       mv \$SOURCES \$SOURCES.bak
       echo "# KSPD REPO BEGIN" > \$SOURCES
       echo "# deb http://spb99pcoapp09.gazprom-neft.local/1.7_x86-64/repository-main/ 1.7_x86-64 main contrib non-free" >> \$SOURCES
       echo "# deb http://spb99pcoapp09.gazprom-neft.local/1.7_x86-64/repository-update/ 1.7_x86-64 main contrib non-free" >> \$SOURCES
       echo "# deb http://spb99pcoapp09.gazprom-neft.local/1.7_x86-64/repository-base/ 1.7_x86-64 main contrib non-free" >> \$SOURCES
       echo "# deb http://spb99pcoapp09.gazprom-neft.local/1.7_x86-64/repository-extended/ 1.7_x86-64 main contrib non-free" >> \$SOURCES
       echo "# deb [arch=amd64] http://spb99pcoapp09.gazprom-neft.local/repos/buster/debian-security/ 1.7_x86-64 main" >> \$SOURCES
       echo "# deb [arch=amd64] http://spb99pcoapp09.gazprom-neft.local/repos/buster/third-party/ 1.7_x86-64 main" >> \$SOURCES
       echo "# KSPD REPO END" >> \$SOURCES
       echo >> \$SOURCES
       echo "# ASTRA-LINUX REPO BEGIN" >> \$SOURCES
       echo "deb https://download.astralinux.ru/astra/stable/1.7_x86-64/repository-main/ 1.7_x86-64 main contrib non-free" >> \$SOURCES
       echo "deb https://download.astralinux.ru/astra/stable/1.7_x86-64/repository-update/ 1.7_x86-64 main contrib non-free" >> \$SOURCES
       echo "deb https://download.astralinux.ru/astra/stable/1.7_x86-64/repository-base/ 1.7_x86-64 main contrib non-free" >> \$SOURCES
       echo "deb https://download.astralinux.ru/astra/stable/1.7_x86-64/repository-extended/ 1.7_x86-64 main contrib non-free" >> \$SOURCES
       echo "# ASTRA-LINUX REPO END" >> \$SOURCES
       echo >> \$SOURCES
       echo "# LOCAL REPO BEGIN" >> \$SOURCES
       echo "deb file://\$MOUNTPOINT/repo/mirror/spb99pcoapp09.gazprom-neft.local/repos/buster/debian-security/ 1.7_x86-64 main" >> \$SOURCES
       echo "deb file://\$MOUNTPOINT/repo/mirror/spb99pcoapp09.gazprom-neft.local/repos/buster/third-party/ 1.7_x86-64 main" >> \$SOURCES
       echo "# LOCAL REPO END" >> \$SOURCES
       wget -qO - file://\$MOUNTPOINT/repo/mirror/spb99pcoapp09.gazprom-neft.local/repos/gpg.key | apt-key add -
fi
echo "=====================================================" >> \$LOG
apt update >> \$LOG

# System configuration to run updates
git --version &> /dev/null
if [ 0 != `echo \$\?` ]
   then
       echo -e "\n\${YELLOW}### УСТАНОВКА НЕОБХОДИМЫХ ПАКЕТОВ ###\n" | tee -a \$LOG
       apt install -y git >> \$LOG
       apt install -y ansible >> \$LOG
       apt install -y python >> \$LOG
       apt install -y openssh-server >> \$LOG
       apt install -y dnsutils >> \$LOG
fi
cd \$MOUNTPOINT/remediations-roles
echo "=====================================================" >> \$LOG

# Host section modification
sed -i 's/\(^\s*- hosts: \)\(.*\)/\1localhost/g' ./mobile-device-offline.yml

# Check install package
ansible --version >> \$LOG
if [ 0 == `echo \$\?` ]
  # Update system
  then echo -e "\n\${YELLOW}### ЗАПУСК ОБНОВЛЕНИЙ ###\n" | tee -a \$LOG
       ansible-playbook ./mobile-device-offline.yml | tee -a \$LOG
       grep failed=0 /var/log/ansible.log &> /dev/null
       if [ 0 = `echo \$\?` ]
          then echo -e "\n\${GREEN}### ОБНОВЛЕНИЕ ВЫПОЛНЕНО УСПЕШНО ###\n" | tee -a \$LOG
          else echo -e "\n\${RED}### ОБНОВЛЕНИЕ ВЫПОЛНЕНО С ОШИБКАМИ СМОТРИТЕ (/var/log/ansible.log) ###\n" | tee -a \$LOG
       fi
  else echo -e "\n\${RED}### ПРОВЕРЬТЕ СЕТЕВЫЕ СОЕДИНЕНИЯ\nИЛИ ПОПРОБУЙТЕ ЗАПУСТИТЬ СУЕНАРИЙ ЕЩЕ РАЗ ###\n" | tee -a \$LOG
       exit 1
fi
EOL

# Очистка системы
echo -e "\n${YELLOW}### ОЧСТКА СИСТЕМЫ ###\n"
if [ /mnt/mirror = `pwd` ]
   then cd ~
        umount /mnt/mirror
        df -Th | grep /mnt/mirror
        if [ 0 != `echo $?` ]
           then rm -rf /mnt/mirror
        fi
   else umount /mnt/mirror
        df -Th | grep /mnt/mirror
        if [ 0 != `echo $?` ]
           then rm -rf /mnt/mirror
        fi
fi

# Скрипт закончил свою работу
if [ 0 = `echo $?` ]
   then echo -e "\n${YELLOW}### ЛОКАЛЬНЫЙ РЕПОЗИТОРИЙ ГОТОВ К ИСПОЛЬЗОВАНИЮ ###\n"
   elif [ 0 != `echo $?` ]
   then echo -e "\n${RED}### ЛОКАЛЬНЫЙ РЕПОЗИТОРИЙ ГОТОВ К ИСПОЛЬЗОВАНИЮ ###\n### ОШИБКА РАЗМОНТИРОВАНИЯ НАКОПИТЕЛЯ!!! ###"
fi
