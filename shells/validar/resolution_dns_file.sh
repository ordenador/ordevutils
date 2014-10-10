CMD_SSH='ssh -n'
HOSTS=''
IP=''
hostname=''
salida=hosts_dns_order.log
        nodo=$1
        os=`$CMD_SSH $nodo uname -s`
        DNS=`nslookup $nodo | egrep -v "DNS.com|108.0.1.45|Name" | awk '{print $2}' | sed 's/^[ v]*//'|sed '/^$/d'`
        hostname=`$CMD_SSH $nodo hostname`

        echo "############## $nodo - $os #################" >> $salida
        echo "############## $nodo - $os #################"
        if [ $os = "Linux" ]; then
            IP=`$CMD_SSH $nodo ifconfig -a | grep inet | grep -v 'inet6' |head -1 | awk -F: '{print $2}' | awk '{print $1}'`
            hostname=`$CMD_SSH $nodo hostname`
            HOSTS=`$CMD_SSH $nodo grep hosts: /etc/nsswitch.conf | grep -v '#'`
        elif [ $os = "AIX" ]; then
            IP=`$CMD_SSH $nodo ifconfig -a | grep inet |head -1 | awk '{ print $2 }'`
            hostname=`$CMD_SSH $nodo hostname`
            HOSTS=`$CMD_SSH $nodo grep hosts= /etc/netsvc.conf | grep -v '#'`
        fi
        echo "HOSTNAME: "$hostname >> $salida
        echo "HOSTNAME: "$hostname
        echo "DNS: "$DNS >> $salida
        echo "DNS: "$DNS
        echo "IP: "$IP >> $salida
        echo "IP: "$IP
        echo $nodo";"$hostname";"$DNS";"$IP";"$HOSTS >> $salida
        echo $nodo";"$hostname";"$DNS";"$IP";"$HOSTS
