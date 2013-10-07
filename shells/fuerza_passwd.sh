#!/bin/ksh
# fuerza_passwd.sh server
# Formato 'archivoPassword': username;password
archivoPassword='user_pass.txt'
cuenta=`cat $archivoPassword | wc -l`
cuenta=$(( cuenta - 0 ))
while [ $cuenta -ge  1 ]
      do
      linea=`cat $archivoPassword | tail -$cuenta | head -1`
      usrname=`echo $linea | awk -F";" '{print $1}'`
      usrpass=`echo $linea | awk -F";" '{print $2}'`
echo "####################   "$1";"$linea"   #####################"
ssh $1 passwd $usrname << ff
$usrpass
$usrpass
ff
echo ""
cuenta=$(( cuenta - 1 ))
done
