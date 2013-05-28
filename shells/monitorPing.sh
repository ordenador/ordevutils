#!/bin/ksh
#
# Monitoreo de PING
#
# EXEC: nohup /bin/ksh /root/monitoreo/moniphear.sh &
#
# Paquetes y rtt
# Transmitidos;Recibidos;Perdidos;tiempo;min;avg;max;mdev
#
##########################################################
pingn="3"
nodoip="96.1.1.50"
while true; do
        fecha=`date '+%F'`
        hora=`date '+%T'`
        ping=`ping -c $pingn $nodoip | awk '$0' ORS='\\\n'`
        parte1=`echo -e $ping | grep received | awk '{print $1";"$4";"$6";"$10}'`
        parte2=`echo -e $ping | grep rtt | awk '{print $4}' | awk -F '/' '{print $1";"$2";"$3";"$4}'`
        echo ${fecha} ${hora}";"$parte1";"$parte2 >> monitor_ip_heartbeat_${fecha}.csv
done