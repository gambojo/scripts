#!/bin/bash

# Vars
gen_policy="usbguard generate-policy -P"
rules_tmp="/tmp/rules_tmp"
rules="/etc/usbguard/rules.conf"
rules_bak="/etc/usbguard/rules.conf.bak"
new_devices="/tmp/new_devices"
present="/tmp/present"

# Backup exist roles
cp $rules $rules_bak

# Generation conf-file for usbguard
$gen_policy > $rules_tmp

# Checking conf-files
dev=$(diff $rules_tmp rules | sed -ne '/</p' | sed -e "s/\(^<\s*\)\(.*\)\(\)/\2/g")
echo $dev | sed 's/\(allow*\)/\n\1/g' | sed '/^\s*$/d' | nl -n ln | sed 's/\(^[0-9]\)\(\s*\)\(.*\)/\1 \3/g' > $new_devices
echo $dev | sed 's/\(allow*\)/\n\1/g' | sed '/^\s*$/d' | cut -d'"' -f4 | nl -n ln | sed 's/\(^[0-9]\)\(\s*\)\(.*\)/\1 \3/g' > $present

# Allow device
echo -e "Выберите порядковый номер устройства, которое необходимо добавить,\nили нажмите (*) для добавления всех устройств:"
cat $present
read target_devices
case $target_devices in
  1) sed -n '/^'$target_devices'/p' $new_devices | sed 's/\(^[0-9]\) \(.*\)/\2/g' >> $rules;;
  2) sed -n '/^'$target_devices'/p' $new_devices | sed 's/\(^[0-9]\) \(.*\)/\2/g' >> $rules;;
  3) sed -n '/^'$target_devices'/p' $new_devices | sed 's/\(^[0-9]\) \(.*\)/\2/g' >> $rules;;
  4) sed -n '/^'$target_devices'/p' $new_devices | sed 's/\(^[0-9]\) \(.*\)/\2/g' >> $rules;;
  5) sed -n '/^'$target_devices'/p' $new_devices | sed 's/\(^[0-9]\) \(.*\)/\2/g' >> $rules;;
  *) echo "$dev" >> $rules;;
esac

# Control permissions
chmod 600 $rules

# Restart service
systemctl restart usbguard

# Clean trash
rm -rf $tmp $new_devices

device=$(tail -n 1 $rules | cut -d'"' -f4)
echo -e "### Устройство \"$device\" добавленно ###\n"