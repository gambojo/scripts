#!/bin/bash

# Vars
GEN_POLICY="usbguard generate-policy -P"
RULES_TMP="/tmp/rules_tmp"
RULES="/etc/usbguard/rules.conf"
RULES_BAK="/etc/usbguard/rules.conf.bak"
NEW_DEVICES="/tmp/new_devices"
PRESENT="/tmp/present"

# Backup exist roles
cp $RULES $RULES_BAK

# Generation conf-file for usbguard
$GEN_POLICY > $RULES_TMP

# Checking conf-files
DEV=$(diff $RULES_TMP $RULES | sed -ne '/</p' | sed -e "s/\(^<\s*\)\(.*\)\(\)/\2/g")
echo $DEV | sed 's/\(allow*\)/\n\1/g' | sed '/^\s*$/d' | nl -n ln | sed 's/\(^[0-9]\)\(\s*\)\(.*\)/\1 \3/g' > $NEW_DEVICES
echo $DEV | sed 's/\(allow*\)/\n\1/g' | sed '/^\s*$/d' | cut -d'"' -f4 | nl -n ln | sed 's/\(^[0-9]\)\(\s*\)\(.*\)/\1 \3/g' > $PRESENT

# Allow device
echo -e "Выберите порядковый номер устройства, которое необходимо добавить,\nили нажмите (9) для добавления всех устройств:"
cat $PRESENT
read TARGET_DEVICES
if [ "$TARGET_DEVICES" -ge 1 -a "$TARGET_DEVICES" -ne 9 ]
   then sed -n '/^'$TARGET_DEVICES'/p' $NEW_DEVICES | sed 's/\(^[0-9]\) \(.*\)/\2/g' >> $RULES
   elif [ "$TARGET_DEVICES" -eq 9 ]
        then echo "$DEV" >> $RULES
fi

# Control permissions
chmod 600 $RULES

# Restart service
systemctl restart usbguard

# Clean trash
rm -rf $RULES_TMP $NEW_DEVICES
DEVICE=$(tail -n 1 $RULES | cut -d'"' -f4)
echo -e "### Устройство \"$DEVICE\" добавленно ###\n"
unset -v GEN_POLICY RULES_TMP RULES RULES_BAK NEW_DEVICES PRESENT DEV TARGET_DEVICES DEVICE

# Done