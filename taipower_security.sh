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

