#!/bin/bash
#
# Replica filesystems, 2 servidores via rsync
# Version 2.0
# Autor: Mario Faundez(Ordenador, mariofaundez@hotmail.com)
#
###############################################################################
######################### VARIABLES DE CONFIGURACION ##########################

NOMBRE_SITIO1="nombre-sitio1"
NOMBRE_SITIO2="nombre-sitio2"

################################ SCRIPT INIT ##################################

### Funcion rsync que realiza al pasar todas las valicadiones
# Copia de archivos
copy_rsync() {
    ipReplica="$1"
    echo "Se inicia la replica hacia $ipReplica !"
    #/bin/sh -xc "rsync -va /home/ordenador/test/rsync/ $ipReplica:/home/ordenador/test/rsync/"
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
printf "DATE: "
/bin/date

### Variables varias
RED='\e[0;31m'
GREEN='\e[0;32m'
YELLOW='\e[0;33m'
COLOR_OFF='\e[0m'
CMD_GREP="/bin/grep --color=never"
CMD_IFCONFIG="/sbin/ifconfig"

## Obtener Hostname
HOSTNAME_LOCAL=`hostname -s`
### Obtener SITIO LOCAL
site_tmp=`$CMD_GREP "SITE=" /sist_bin/basico.prf  || echo '"none'`
SITE=`echo ${site_tmp} | awk -F '\"|\"' '{print $2}'`

## Obtener ip desde DNS
NSLOOKUP_SITIO1=`nslookup $NOMBRE_SITIO1 | $CMD_GREP -Eo 'Address:( )*([0-9]*\.){3}[0-9]*' | $CMD_GREP -Eo '([0-9]*\.){3}[0-9]*'`
NSLOOKUP_SITIO2=`nslookup $NOMBRE_SITIO2 | $CMD_GREP -Eo 'Address:( )*([0-9]*\.){3}[0-9]*' | $CMD_GREP -Eo '([0-9]*\.){3}[0-9]*'`
NSLOOKUP_NOMBRE_PROD=`nslookup $HOSTNAME_LOCAL | $CMD_GREP -Eo 'Address:( )*([0-9]*\.){3}[0-9]*' | $CMD_GREP -Eo '([0-9]*\.){3}[0-9]*'`

NOMBRE_REPLICA=''
## Obtener Nombre Replica
if [ "$NSLOOKUP_NOMBRE_PROD" == "$NSLOOKUP_SITIO1" ] && [ "$NSLOOKUP_NOMBRE_PROD" != "$NSLOOKUP_SITIO2" ]; then
    NOMBRE_REPLICA=$NOMBRE_SITIO2
elif [ "$NSLOOKUP_NOMBRE_PROD" == "$NSLOOKUP_SITIO2" ] && [ "$NSLOOKUP_NOMBRE_PROD" != "$NSLOOKUP_SITIO1" ]; then
    NOMBRE_REPLICA=$NOMBRE_SITIO1
fi

if [ "$NOMBRE_REPLICA" == "" ];then
    echo -e "${RED}>>> NO SE REALIZA COPIA DE ARCHIVOS <<<"
    echo -e "NO SE PUDO OBTENER NOMBRE DEL SERVIDOR REPLICA.${COLOR_OFF}"
    echo -e "Favor revisar:"
    echo -e "\t-> Variables de configuracion\n"
    exit 2
fi

### IP asociado al nombre DNS Replica
NSLOOKUP_NOMPRE_REPLICA=`nslookup $NOMBRE_REPLICA | $CMD_GREP -Eo 'Address:( )*([0-9]*\.){3}[0-9]*' | $CMD_GREP -Eo '([0-9]*\.){3}[0-9]*'`

### IP de interfaces de red
IP_ETH_LOCAL=`$CMD_IFCONFIG | $CMD_GREP -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | $CMD_GREP -Eo '([0-9]*\.){3}[0-9]*' | $CMD_GREP -v '127.0.0.1'`

### Mostrar datos:
echo -e "Datos:"
echo -e "DNS de Produccion '$HOSTNAME_LOCAL': $NSLOOKUP_NOMBRE_PROD"
echo -e "DNS de Replica '$NOMBRE_REPLICA': $NSLOOKUP_NOMPRE_REPLICA"
echo -e "Sitio Local: $SITE"
echo -e "IP(s) local: $IP_ETH_LOCAL\n"

### Pre-Validacion Por Nombres
if ( contains "$NOMBRE_REPLICA" "$HOSTNAME_LOCAL" ); then
    echo "Pre Validacion por Nombre OK: Existe similitud entre los nombres de produccion y replica."
else
    echo -e "${RED}>>> NO SE REALIZA COPIA DE ARCHIVOS <<<"
    echo -e "NO EXISTE SIMILITUD ENTRE LOS NOMBRES DE PRODUCCION Y REPLICA.${COLOR_OFF}"
    echo -e "Favor revisar:"
    echo -e "\t-> Variables de configuracion\n"
    exit 2
fi

### Pre-Validacion de DNS respecto a la maquina REPLICA
if [ "$NSLOOKUP_NOMBRE_PROD" == "$NSLOOKUP_NOMPRE_REPLICA" ]; then
        echo -e "${RED}>>> NO SE REALIZA COPIA DE ARCHIVOS <<<"
        echo -e "LA IP DE REPLICA ES IGUAL A LA IP DE PRODUCCION.${COLOR_OFF}"
        echo -e "Favor revisar:"
        echo -e "\t-> Es la maquina de origen?"
        echo -e "\t-> Variables de configuracion\n"
        exit 2
else
        echo  -e "Pre Validacion por IP/DNS de los servidores OK: La IP del DNS '${NOMBRE_REPLICA}' NO es igual a la IP del DNS '${HOSTNAME_LOCAL}'."
fi

### Validacion de DNS respecto a las IP(s) locales
if ( contains "$IP_ETH_LOCAL" "$NSLOOKUP_NOMBRE_PROD" ); then
		echo -e "Validacion OK: Existe conincidencia de IP local relacionado con nombre DNS '$HOSTNAME_LOCAL'.\n"
        echo -e "${GREEN}Inicio copia de arhivos. Desde: '$HOSTNAME_LOCAL-$SITE', Hacia: '$NOMBRE_REPLICA'\n${YELLOW}###############################################################################${COLOR_OFF}"
        copy_rsync $NSLOOKUP_NOMPRE_REPLICA
        echo -e "${YELLOW}###############################################################################\n${GREEN}Fin de copia de archivos.${COLOR_OFF}\n"
        exit 0
else
        echo -e "DNS de $HOSTNAME_LOCAL: $NSLOOKUP_NOMBRE_PROD"
        echo -e "IPs de $HOSTNAME_LOCAL: $IP_ETH_LOCAL"
        echo -e "\n${RED}>>> NO SE REALIZA COPIA DE ARCHIVOS <<<"
        echo -e "EL DNS DEL NOMBRE PRODUCCION: '$HOSTNAME_LOCAL' NO APUNTA A ESTE NODO.${COLOR_OFF}"
        echo -e "Favor revisar:"
        echo -e "\t-> Es la maquina de origen?"
        echo -e "\t-> Variables de configuracion\n"
        exit 2
fi
