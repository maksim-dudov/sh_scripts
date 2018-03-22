#!/bin/sh

##author codemaks 20140404
##reba = reboot apache
##script reboots apache if the swap exceeds 10%
##sorry for english. koi8-r/cp1251/utf-8/cp866 - fuck them all! hope you'll understand me

#check does the swap exists
isswap=`top -b | grep Swap | grep Inuse`
if [ "$isswap" ];
then

#if exists, get the procent "Inuse" and compare it with 10%
if [ `top -b | grep Swap | grep Inuse | cut -d '%' -f 1 | cut -d ',' -f 4` -gt 25 ];
then
#write the current process list to the temporary file
top -o res > /usr/home/friendsplace/data/www/debug.online.friendsplace.ru/trunk/top.tmp
#reboot
/usr/local/sbin/apachectl restart
#launch php script, which will send email
/usr/local/bin/wget -q http://debug.online.friendsplace.ru/mail.php
fi
fi