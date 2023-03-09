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

#check passwordless
min=`grep '^UID_MIN' /etc/login.defs | awk '{print $2}'`
max=`grep '^UID_MAX' /etc/login.defs | awk '{print $2}'`

all=`cat fake_passwd`
for i in $all;do
  acct=`echo $i | cut -d : -f 1`
  id=`echo $i | cut -d : -f 3`
  if [ $id -le $max ] && [ $id -ge $min ]
    then
      if grep -q "^$acct:\!\!" fake_shadow
        then
          echo 'give me a password'
      fi
  fi
done
