#!/bin/ksh
#
# Replica configuraciones escenciales del Sistema Operativo
# Version 3.0
# Autor: Mario Faundez(Ordenador, mariofaundez@hotmail.com)
#
###############################################################################
######################### VARIABLES DE CONFIGURACION ##########################
NOMBRE_SITIO1="repolinux"
NOMBRE_SITIO2="tecnecio"

## Variables de sincronizacion, usar valores: true, false
COLAS_IMPRESORA=false
CRONTAB=false
SIST_BIN=false
SYSCTL=false
EXECAS=false
USUARIOS=false

################################ SCRIPT INIT ##################################

### Funcion sync que realiza al pasar todas las valicadiones
# Copia de archivos
copy_sync() {
    ipReplica="$1"
    $CMD_ECHO "Se inicia la replica hacia $ipReplica !"

    if [ "$COLAS_IMPRESORA" == "true" ]; then
        $CMD_ECHO ">>> Sinconizando Colas de Impresion:"
        if [ "$SO" == "Linux" ];then
            /bin/sh -xc "scp /etc/cups/printers.conf $ipReplica:/etc/cups"
            /bin/sh -xc "scp -r /etc/cups/ppd $ipReplica:/etc/cups/"
            /bin/sh -xc "ssh $ipReplica /etc/init.d/cups restart"
        elif [ "$SO" == "AIX" ]; then
            /bin/sh -xc "scp /etc/qconfig $ipReplica:/etc"
            /bin/sh -xc "scp -r /var/spool/lpd/pio/@local/custom $ipReplica:/var/spool/lpd/pio/@local/"
            /bin/sh -xc "scp -r /var/spool/lpd/pio/@local/dev $ipReplica:/var/spool/lpd/pio/@local/"
            /bin/sh -xc "ssh $ipReplica chmod 664 /var/spool/lpd/pio/@local/custom/*"
            /bin/sh -xc "ssh $ipReplica chgrp printq /var/spool/lpd/pio/@local/custom/*"
            /bin/sh -xc "ssh $ipReplica stopsrc -g spooler"
            /bin/sh -xc "ssh $ipReplica startsrc -g spooler"
        fi
    fi

    if [ "$CRONTAB" == "true" ]; then
        $CMD_ECHO ">>> Sinconizando Crontab:"
        if [ "$SO" == "Linux" ];then
            /bin/sh -xc "rsync -av /var/spool/cron/ $ipReplica:/var/spool/cron/"
        elif [ "$SO" == "AIX" ]; then
            /bin/sh -xc "scp -r /var/spool/cron $ipReplica:/var/spool/"
        fi
    fi

    if [ "$SIST_BIN" == "true" ]; then
        $CMD_ECHO ">>> Sinconizando '/sist_bin/':"
        /bin/sh -xc "rsync -av --exclude='oracle.prf' --exclude='basico.prf' /sist_bin/ $ipReplica:/sist_bin/"
    fi

    if [ "$SYSCTL" == "true" ]; then
        $CMD_ECHO ">>> Sinconizando '/etc/sysctl.conf':"
        if [ "$SO" == "Linux" ];then
            /bin/sh -xc "scp /etc/sysctl.conf $ipReplica:/etc/"
        else
            $CMD_ECHO "En maquinas AIX no se sincroniza /etc/sysctl.conf"
        fi
    fi

    if [ "$EXECAS" == "true" ]; then
        $CMD_ECHO ">>> Sinconizando '/usr/local/etc/execas.dat':"
        /bin/sh -xc "scp /usr/local/etc/execas.dat $ipReplica:/usr/local/etc/execas.dat"
    fi

    if [ "$USUARIOS" == "true" ]; then
        $CMD_ECHO ">>> Sinconizando Usuarios:"
        /bin/sh -xc "scp /etc/group $ipReplica:/etc/"
        /bin/sh -xc "scp /etc/passwd $ipReplica:/etc/"
        if [ "$SO" == "Linux" ];then
            /bin/sh -xc "scp /etc/shadow $ipReplica:/etc/"
            /bin/sh -xc "rsync -va /etc/security/ $ipReplica:/etc/security/"
        fi
        if [ "$SO" == "AIX" ];then
            /bin/sh -xc "scp /etc/security/group $ipReplica:/etc/security/"
            /bin/sh -xc "scp /etc/security/limits $ipReplica:/etc/security/"
            /bin/sh -xc "scp /etc/security/passwd $ipReplica:/etc/security/"
            /bin/sh -xc "scp /etc/security/.ids $ipReplica:/etc/security/"
            /bin/sh -xc "scp /etc/security/environ $ipReplica:/etc/security/"
            /bin/sh -xc "scp /etc/security/login.cfg $ipReplica:/etc/security/"
            /bin/sh -xc "scp /etc/security/user $ipReplica:/etc/security/"
        fi
    fi
}

## Validacion rsync
validar_rsync(){
    ipReplica="$1"
    whichRsyncLocal=`which rsync > /dev/null 2>&1;echo $?`
    whichRsyncRemote=`ssh $ipReplica which rsync > /dev/null 2>&1;echo $?`
    if [ $whichRsyncLocal -eq 1 ];then
        $CMD_ECHO "Validación rsync: Esta maquina no tiene rsync. Se cancela ejecucion."
        exit 1
    fi
    if [ $whichRsyncRemote -eq 1 ];then
        $CMD_ECHO "Validación rsync: Maquina '$ipReplica' no tiene rsync. Se cancela ejecucion."
        exit 1
    fi
}

### Funcion que compara si un string es parte de otro string
# contains(string, substring)
#
# Returns 0 if the specified string contains the specified substring,
# otherwise returns 1.
contains() {
    string="$1"
    substring="$2"
    if test "${string#*$substring}" != "$string"
    then
        return 0    # $substring is in $string
    else
        return 1    # $substring is not in $string
    fi
}

echo "###############################  INICIO  ######################################"
printf "DATE: ";/bin/date

### Variables varias
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
COLOR_OFF='\033[0m'

## Obtener SO
SO=`uname -s`

## Variables: AIX y Linux
if [ "$SO" == "Linux" ];then
    CMD_ECHO="echo -e"
    ### IP de interfaces de red
    IP_ETH_LOCAL=`ifconfig | grep "inet " | awk '{print $2}' | grep -v 127.0.0.1 | awk -F: '{print $2}'`
elif [ "$SO" == "AIX" ]; then
    CMD_ECHO="echo"
    ### IP de interfaces de red
    IP_ETH_LOCAL=`ifconfig -a | grep 'inet ' | awk '{print $2}' | grep -v 127.0.0.1`
fi

## Obtener Hostname
HOSTNAME_LOCAL=`hostname -s`
### Obtener SITIO LOCAL
site_tmp=`grep "SITE=" /sist_bin/basico.prf  || echo '"none'`
SITE=`echo ${site_tmp} | awk -F '\"|\"' '{print $2}'`


## Obtener resolucion DNS
DNS_RESOLV=`cat /etc/resolv.conf | grep -v '^#' | grep nameserver | awk '{print $NF}'`

## Obtener ip desde DNS
NSLOOKUP_SITIO1=`nslookup $NOMBRE_SITIO1 2> /dev/null | grep -v $DNS_RESOLV | grep Addres | awk '{print $NF}'`
NSLOOKUP_SITIO2=`nslookup $NOMBRE_SITIO2 2> /dev/null | grep -v $DNS_RESOLV | grep Addres | awk '{print $NF}'`
NSLOOKUP_NOMBRE_PROD=`nslookup $HOSTNAME_LOCAL 2> /dev/null | grep -v $DNS_RESOLV | grep Addres | awk '{print $NF}'`

## Validacion de DNS de los servidores involucrados
if [ "$NSLOOKUP_SITIO1" == "" ];then
    $CMD_ECHO "${RED}>>> NO SE REALIZA COPIA DE ARCHIVOS <<<"
    $CMD_ECHO "NO SE PUDO OBTENER 'NOMBRE_SITIO1'.${COLOR_OFF}"
    $CMD_ECHO "Favor revisar:"
    $CMD_ECHO "\t-> Variables de configuracion\n"
    exit 2
fi
if [ "$NSLOOKUP_SITIO2" == "" ];then
    $CMD_ECHO "${RED}>>> NO SE REALIZA COPIA DE ARCHIVOS <<<"
    $CMD_ECHO "NO SE PUDO OBTENER 'NOMBRE_SITIO2'.${COLOR_OFF}"
    $CMD_ECHO "Favor revisar:"
    $CMD_ECHO "\t-> Variables de configuracion\n"
    exit 2
fi
if [ "$NSLOOKUP_NOMBRE_PROD" == "" ];then
    $CMD_ECHO "${RED}>>> NO SE REALIZA COPIA DE ARCHIVOS <<<"
    $CMD_ECHO "NO SE PUDO OBTENER DNS del Hostname.${COLOR_OFF}"
    $CMD_ECHO "Favor revisar:"
    $CMD_ECHO "\t-> Variables de configuracion\n"
    exit 2
fi

## Obtener Nombre Replica
NOMBRE_REPLICA=''
## Obtener Nombre Replica
if [ "$NSLOOKUP_NOMBRE_PROD" == "$NSLOOKUP_SITIO1" ] && [ "$NSLOOKUP_NOMBRE_PROD" != "$NSLOOKUP_SITIO2" ]; then
    NOMBRE_REPLICA=$NOMBRE_SITIO2
elif [ "$NSLOOKUP_NOMBRE_PROD" == "$NSLOOKUP_SITIO2" ] && [ "$NSLOOKUP_NOMBRE_PROD" != "$NSLOOKUP_SITIO1" ]; then
    NOMBRE_REPLICA=$NOMBRE_SITIO1
fi

## Valicadion Nombre Replica
if [ "$NOMBRE_REPLICA" == "" ];then
    $CMD_ECHO "${RED}>>> NO SE REALIZA COPIA DE ARCHIVOS <<<"
    $CMD_ECHO "NO SE PUDO OBTENER NOMBRE DEL SERVIDOR REPLICA.${COLOR_OFF}"
    $CMD_ECHO "Favor revisar:"
    $CMD_ECHO "\t-> Variables de configuracion\n"
    exit 3
fi

### IP asociado al nombre DNS Replica
NSLOOKUP_NOMPRE_REPLICA=`nslookup $NOMBRE_REPLICA | grep -v $DNS_RESOLV | grep Addres | awk '{print $NF}'`

### Mostrar datos:
$CMD_ECHO "Datos:"
$CMD_ECHO "DNS de Produccion '$HOSTNAME_LOCAL': $NSLOOKUP_NOMBRE_PROD"
$CMD_ECHO "DNS de Replica '$NOMBRE_REPLICA': $NSLOOKUP_NOMPRE_REPLICA"
$CMD_ECHO "Sitio Local: $SITE"
$CMD_ECHO "IP(s) local: $IP_ETH_LOCAL\n"

## Pre-Validacion Por Nombres
if ( contains "$NOMBRE_REPLICA" "$HOSTNAME_LOCAL" ); then
    $CMD_ECHO "Pre Validacion por Nombre OK: Existe similitud entre los nombres de produccion y replica."
else
    $CMD_ECHO "${RED}>>> NO SE REALIZA COPIA DE ARCHIVOS <<<"
    $CMD_ECHO "NO EXISTE SIMILITUD ENTRE LOS NOMBRES DE PRODUCCION Y REPLICA.${COLOR_OFF}"
    $CMD_ECHO "Favor revisar:"
    $CMD_ECHO "\t-> Variables de configuracion\n"
    exit 4
fi

### Pre-Validacion de DNS respecto a la maquina REPLICA
if [ "$NSLOOKUP_NOMBRE_PROD" == "$NSLOOKUP_NOMPRE_REPLICA" ]; then
        $CMD_ECHO "${RED}>>> NO SE REALIZA COPIA DE ARCHIVOS <<<"
        $CMD_ECHO "LA IP DE REPLICA ES IGUAL A LA IP DE PRODUCCION.${COLOR_OFF}"
        $CMD_ECHO "Favor revisar:"
        $CMD_ECHO "\t-> Es la maquina de origen?"
        $CMD_ECHO "\t-> Variables de configuracion\n"
        exit 5
else
        $CMD_ECHO "Pre Validacion por IP/DNS de los servidores OK: La IP del DNS '${NOMBRE_REPLICA}' NO es igual a la IP del DNS '${HOSTNAME_LOCAL}'."
fi

### Validacion de DNS respecto a las IP(s) locales
if ( contains "$IP_ETH_LOCAL" "$NSLOOKUP_NOMBRE_PROD" ); then
		$CMD_ECHO "Validacion OK: Existe conincidencia de IP local relacionado con nombre DNS '$HOSTNAME_LOCAL'.\n"
        validar_rsync $NSLOOKUP_NOMPRE_REPLICA
        $CMD_ECHO "${GREEN}Inicio copia de arhivos. Desde: '$HOSTNAME_LOCAL-$SITE', Hacia: '$NOMBRE_REPLICA'\n${YELLOW}###############################################################################${COLOR_OFF}"
        copy_sync $NSLOOKUP_NOMPRE_REPLICA
        $CMD_ECHO "${YELLOW}###############################################################################\n${GREEN}Fin de copia de archivos.${COLOR_OFF}\n"
        exit 0
else
        $CMD_ECHO "DNS de $HOSTNAME_LOCAL: $NSLOOKUP_NOMBRE_PROD"
        $CMD_ECHO "IPs de $HOSTNAME_LOCAL: $IP_ETH_LOCAL"
        $CMD_ECHO "\n${RED}>>> NO SE REALIZA COPIA DE ARCHIVOS <<<"
        $CMD_ECHO "EL DNS DEL NOMBRE PRODUCCION: '$HOSTNAME_LOCAL' NO APUNTA A ESTE NODO.${COLOR_OFF}"
        $CMD_ECHO "Favor revisar:"
        $CMD_ECHO "\t-> Es la maquina de origen?"
        $CMD_ECHO "\t-> Variables de configuracion\n"
        exit 6
fi
