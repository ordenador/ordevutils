CMD_SSH='ssh -n -o PasswordAuthentication=no'
IP=''
hostname=''
osver=''
version=''
rpmHDLM=''
salida=hdlm_so_linux.log
        nodo=$1
        os=`$CMD_SSH $nodo uname -s`
        DNS=`nslookup $nodo | egrep -v "***REMOVED***.cl|108.0.1.45|Name" | awk '{print $2}' | sed 's/^[ v]*//'|sed '/^$/d'`
        hostname=`$CMD_SSH $nodo hostname`

        if [ $os = "Linux" ]; then
            IP=`$CMD_SSH $nodo ifconfig -a | grep inet | grep -v 'inet6' |head -1 | awk -F: '{print $2}' | awk '{print $1}'`
            hostname=`$CMD_SSH $nodo hostname`
            rpmHDLM=`$CMD_SSH $nodo rpm -q HDLM`
            osver=`$CMD_SSH $nodo "if [ -e /etc/oracle-release ]; then echo 'Oracle Linux'; else echo 'Red Hat Linux';fi"`
            version=`$CMD_SSH $nodo cat /etc/redhat-release | awk '{print $7}'`
        fi
        echo $nodo";"$hostname";"$DNS";"$IP";"$rpmHDLM";"$osver" "$version >> $salida
        echo $nodo";"$hostname";"$DNS";"$IP";"$rpmHDLM";"$osver" "$version
