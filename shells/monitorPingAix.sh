#!/bin/ksh
#
# Monitoreo de PING AIX
# PARA AIX
# EXEC: nohup /bin/ksh /root/monitoreo/moniphear.sh &
#
# Paquetes y rtt
# Transmitidos;Recibidos;Perdidos;min;avg;max;
#
##########################################################
pingn="5"
nodoip="10.10.10.10"
while true; do
        fecha=`date '+%Y-%m-%d'`
        hora=`date '+%T'`
        ping=`ping -c $pingn $nodoip | awk '$0' ORS='\\\n'`
        #parte1=`echo -e $ping | grep received | awk '{print $1";"$4";"$6";"$10}'`
        parte1=`echo -e $ping | grep received | awk '{print $1";"$4";"$7}'`
        #parte2=`echo -e $ping | grep rtt | awk '{print $4}' | awk -F '/' '{print $1";"$2";"$3";"$4}'`
        parte2=`echo -e $ping | grep round-trip | awk '{print $4}' | awk -F '/' '{print $1";"$2";"$3}'`
        echo ${fecha} ${hora}";"$parte1";"$parte2 >> monitor_ip_${nodoip}_${fecha}.csv
done
