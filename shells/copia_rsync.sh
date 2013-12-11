#!/bin/bash
# Version 0.0
######################### VARIABLES DE CONFIGURACION ##########################

### Hostname de produccion. Ej: maquina
HOSTNAME_PROD="repolinux"

### Nombre DNS REPLICA. Ej: maquina-sitio
NOMBRE_REPLICA="tecnecio"

################################ SCRIPT INIT #################################
### Variables varias
RED='\e[0;31m'
GREEN='\e[0;32m'
YELLOW='\e[0;33m'
COLOR_OFF='\e[0m'
CMD_GREP="grep --color=never"

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

### Obtener SITIO LOCAL
site_tmp=`grep "SITE=" /sist_bin/basico.prf  || echo '"none'`
SITE=`echo ${site_tmp} | awk -F '\"|\"' '{print $2}'`

### IP asociado al nombre DNS
NSLOOKUP_NOMBRE_PROD=`nslookup $HOSTNAME_PROD | $CMD_GREP -Eo 'Address:( )*([0-9]*\.){3}[0-9]*' | $CMD_GREP -Eo '([0-9]*\.){3}[0-9]*'`
NSLOOKUP_NOMPRE_REPLICA=`nslookup $NOMBRE_REPLICA | $CMD_GREP -Eo 'Address:( )*([0-9]*\.){3}[0-9]*' | $CMD_GREP -Eo '([0-9]*\.){3}[0-9]*'`

### IP de interfaces de red
IP_ETH_LOCAL=`ifconfig | $CMD_GREP -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | $CMD_GREP -Eo '([0-9]*\.){3}[0-9]*' | $CMD_GREP -v '127.0.0.1'`

### Mostrar datos:
echo -e "Datos:"
echo -e "DNS de Produccion '$HOSTNAME_PROD': $NSLOOKUP_NOMBRE_PROD"
echo -e "DNS de Replica '$NOMBRE_REPLICA': $NSLOOKUP_NOMPRE_REPLICA"
echo -e "IP(s) local: $IP_ETH_LOCAL\n"

### Pre-Validacion de DNS respecto a la maquina REPLICA
if [ "$NSLOOKUP_NOMBRE_PROD" == "$NSLOOKUP_NOMPRE_REPLICA" ]; then
        echo -e "${RED}>>> NO SE REALIZA COPIA DE ARCHIVOS <<<"
        echo -e "LA IP DE REPLICA ES IGUAL A LA IP DE PRODUCCION.${COLOR_OFF}"
        echo -e "Favor revisar:"
        echo -e "\t-> Es la maquina de origen?"
        echo -e "\t-> Variables de configuracion\n"
        exit 2
else
        echo  -e "Pre Validacion OK: La IP de '${NOMBRE_REPLICA}' NO es igual a la IP de '${HOSTNAME_PROD}'"
fi

### Validacion de DNS respecto a las IP(s) locales
if ( contains "$IP_ETH_LOCAL" "$NSLOOKUP_NOMBRE_PROD" ); then
        echo -e "Validacion OK: Existe conincidencia de IP local relacionado con nombre DNS '$HOSTNAME_PROD'.\n"
        echo -e "${GREEN}Inicio copia de arhivos. Desde: '$HOSTNAME_PROD-$SITE', Hacia: '$NOMBRE_REPLICA'\n${YELLOW}###############################################################################${COLOR_OFF}"
        ### Copia de archivos:
        /bin/sh -xc "rsync -va /home/ordenador/test/rsync_origen $NSLOOKUP_NOMPRE_REPLICA:/home/ordenador/test/rsync_destino/"
        echo -e "${YELLOW}###############################################################################\n${GREEN}Fin de copia de archivos.${COLOR_OFF}\n"
        exit 0
else
        echo -e "DNS de $HOSTNAME_PROD: $NSLOOKUP_NOMBRE_PROD"
        echo -e "IPs de $HOSTNAME_PROD: $IP_ETH_LOCAL"
        echo -e "\n${RED}>>> NO SE REALIZA COPIA DE ARCHIVOS <<<"
        echo -e "EL DNS DEL NOMBRE PRODUCCION: '$HOSTNAME_PROD' NO APUNTA A ESTE NODO.${COLOR_OFF}"
        echo -e "Favor revisar:"
        echo -e "\t-> Es la maquina de origen?"
        echo -e "\t-> Variables de configuracion\n"
        exit 2
fi
