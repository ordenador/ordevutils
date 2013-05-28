#!/bin/ksh
# fuerza_passwd.sh server
RUTA=`pwd`
cuenta=`cat $RUTA/user_pass.txt | wc -l`
cuenta=$(( cuenta - 0 ))
while [ $cuenta -ge  1 ]
      do
      linea=`cat $RUTA/user_pass.txt | tail -$cuenta | head -1`
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