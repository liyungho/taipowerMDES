#!/bin/bash

#backup current sssd profile
authselect apply-changes -b --backup=sssd.backup

#create a custom profile
authselect create-profile cht-mdes -b sssd

#switch to custom profile
authselect select custom/cht-mdes

#backup faillock.conf
cp -f /etc/security/faillock.conf /etc/security/faillock.conf.backup.$(date +%F)

#modify faillock.conf
sed -i '/# deny = /s/^# deny = 3/deny = 3/g' /etc/security/faillock.conf
sed -i '/# unlock_time = /s/^# unlock_time = 600/unlock_time = 0/g' /etc/security/faillock.conf

#enable faillock
authselect enable-feature with-faillock

#modify
sed -i '/pam_pwquality.so/a\password    requisite                                    pam_pwhistory.so remember=3 use_authtok' /etc/authselect/custom/cht-mdes/system-auth
sed -i '/pam_pwquality.so/a\password    requisite                                    pam_pwhistory.so remember=3 use_authtok' /etc/authselect/custom/cht-mdes/password-auth

#apply change 
authselect apply-changes

#set password quality
sed -i '/minlen/s/^/#/' /etc/security/pwquality.conf && sed -i '$a\minlen = 12' /etc/security/pwquality.conf
sed -i '/minclass/s/^/#/' /etc/security/pwquality.conf && sed -i '$a\minclass = 4' /etc/security/pwquality.conf
sed -i '/dcredit/s/^/#/' /etc/security/pwquality.conf && sed -i '$a\dcredit = -1' /etc/security/pwquality.conf
sed -i '/ucredit/s/^/#/' /etc/security/pwquality.conf && sed -i '$a\ucredit = -1' /etc/security/pwquality.conf
sed -i '/lcredit/s/^/#/' /etc/security/pwquality.conf && sed -i '$a\lcredit = -1' /etc/security/pwquality.conf
sed -i '/ocredit/s/^/#/' /etc/security/pwquality.conf && sed -i '$a\ocredit = -1' /etc/security/pwquality.conf
sed -i '/maxclassrepeat/s/^/#/' /etc/security/pwquality.conf && sed -i '$a\maxclassrepeat = 2' /etc/security/pwquality.conf

#check accounts without password
min=`grep '^UID_MIN' /etc/login.defs | awk '{print $2}'`
max=`grep '^UID_MAX' /etc/login.defs | awk '{print $2}'`

if [ ! -f "/etc/shadow" ]
  then
    /usr/sbin/pwconv
fi

all=`cat /etc/passwd`
for i in $all;do
  acct=`echo $i | cut -d : -f 1`
  id=`echo $i | cut -d : -f 3`
  if [ $id -le $max ] && [ $id -ge $min ]
    then
      if grep -q "^$acct:\!\!" /etc/shadow
        then
          echo "Give default password to $acct"
          echo "#EDC4rfv%TGB" | passwd --stdin "$acct" #default password 345
      fi
  fi
done
