#!/usr/bin/ksh
# Usar: sitio.sh servidor
#       cat nodos.txt | while read line; do sitio.sh $line; done
HITACHI=""
salida=sitiosalida.txt
        nodo=$1
        os=`ssh $nodo uname -s`
        DNS=`nslookup $nodo | grep -v DNS.com | grep -v 108.0.1.45 | grep -v Name | awk '{print $2}' | sed 's/^[ v]*//'`
        IP=`ssh $nodo ifconfig -a | grep inet |head -1 | awk '{ print $2 }'`
        hostname=`ssh $nodo hostname`

        echo "############## $nodo - $os #################" >> $salida
        echo "############## $nodo - $os #################"
        echo "HOSTNAME: "$hostname >> $salida
        echo "HOSTNAME: "$hostname
        echo "DNS: "$DNS >> $salida
        echo "DNS: "$DNS
        echo "IP: "$IP >> $salida
        echo "IP: "$IP
        if [ $os = "Linux" ]; then
            HITACHI=`ssh $nodo /opt/DynamicLinkManager/bin/dlnkmgr view -lu | grep SerialNumber | awk '{print $3}'`
        elif [ $os = "AIX" ]; then
            HITACHI=`ssh $nodo /usr/DynamicLinkManager/bin/dlnkmgr view -lu | grep SerialNumber | awk '{print $3}'`
        fi

        if [ "$HITACHI" = "0017167" ]; then
            echo "HITACHI: ROSAS" >> $salida
            echo "HITACHI: ROSAS"
        elif [ "$HITACHI" = "0045052" ]; then
            echo "HITACHI: CDLV" >> $salida
            echo "HITACHI: CDLV"
        elif [ "$HITACHI" = "0065382" ]; then
            echo "HITACHI: CDLV" >> $salida
            echo "HITACHI: CDLV"
        elif [ "$HITACHI" = "0065345" ]; then
            echo "HITACHI: GTD" >> $salida
            echo "HITACHI: GTD"
        elif [ "$HITACHI" = "0011268" ]; then
            echo "HITACHI: LO ESPEJO" >> $salida
            echo "HITACHI: LO ESPEJO"
        else
            echo "HITACHI SERIAL NUMBER: "$HITACHI >> $salida
            echo "HITACHI SERIAL NUMBER: "$HITACHI
        fi
        echo ""

        siSanlun=`ssh $nodo which sanlun | grep -c sanlun`
        if [ "$siSanlun" = "0" ]; then
            echo "NETAPP: No es NETAPP" >> $salida
            echo "NETAPP: No es NETAPP"
        else
            NETAPP=`ssh $nodo sanlun lun show | awk '{print $2}'`
            echo "NETAPP: "$NETAPP >> $salida
            echo "NETAPP: "$NETAPP
        fi
        echo ""
