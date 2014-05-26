#!/usr/bin/ksh
# Funciona bien en Linux
# set -x
## Configuracion DB
validateDB=(wmosxdpr wmosxdhi)
validateFS=(AL DB)

## Asociar DB con Filesystem, tipo AL
typeset -A AL
AL["wmosxdpr"]=/u02/ORAARCH/wmosxdpr/
AL["wmosxdhi"]=/u02/ORAARCH/wmosxdhi/

## Asociar DB con Filesystem, tipo DB
typeset -A DB
DB["wmosxdpr"]=/backup/wmosxdpr/
DB["wmosxdhi"]=/backup/wmosxdhi/


###############################################################################
## INIT
USERDB=$1
USERFS=$2
USERDAY=$3

## FUNCIONS
	## Muestra elementos de un arreglo
	listArray(){
		typeset -n array=$1
		for i in ${array[@]}; do
			if [ $i == ${array[0]} ]; then
				printf "$i"
			else
				printf "|$i"
			fi
		done
	}

	## Verifica si existe string dentro de un arreglo
	# containsElement "string" "array"
	containsElement () {
	  typeset -n array=$2
	  for e in "${array[@]}"; do [[ "$e" == "$1" ]] && return 0; done
	  return 1
	}

	## Valida Numero
	validateNumber() {
		if echo $1 | egrep -q '^[0-9]+$'; then
	    	return 0
		else
		    return 1
		fi
	}

	## Function USAGE
	usage(){
		echo ""
		printf "  Usage:\n\n"
		printf "    execas ing_borra_bd (";listArray "validateDB"; printf ") (";listArray "validateFS";printf ") <dias>\n\n"
		printf "    Tipo de borrado (AL|DB):\n"
		printf "        AL: Archive Log\n"
		printf "        DB: Base de datos\n\n"
		printf "    NOTA: Se eliminaran archivos que hayan sufrido modificaciones hace más de <dias> dias\n"
		echo ""
	}

## Validaciones
	## Validar cantidad de argumentos = 3
	if [ ${#} -ne 3 ]; then
		usage
	    exit 255
	fi

	## Validar nombre de DB, tipo filesystem
	if ( (! containsElement ${USERDB} "validateDB") || (! containsElement ${USERFS} "validateFS") ||  (! validateNumber ${USERDAY}) );then
		usage
		## Validar DB
		if ( ! containsElement ${USERDB} "validateDB" );then
			printf "    Favor Usar Base de datos: "; listArray "validateDB"; printf "\n"
		fi

		## Validar TipoFS
		if ( ! containsElement ${USERFS} "validateFS"  );then
			printf "    Favor Usar Filesystems: "; listArray "validateFS"; printf "\n"
		fi

		## Validar <dias>
		if ( ! validateNumber ${USERDAY} );then
			printf "    Favor Usar <dias>: numeros\n\n"
		fi
		exit 10
	fi

## Obtener PATH  y PATRON
	USERPATRON=""
	USERPATH=""
	if [ $USERFS == "AL" ];then
		USERPATH=${AL[$USERDB]}
		USERPATRON="log_*.arc"
	elif [ $USERFS == "DB" ];then
		USERPATH=${DB[$USERDB]}
		USERPATRON="ARC*"
	fi

## Main
echo ""
echo "Verificando datos"
echo "    Base de datos: "$USERDB
echo "    Tipo de Borrado: "$USERFS
echo "    Dias de antiguedad: "$USERDAY
echo ""
echo "Está seguro que desea eliminar: " $USERPATH$USERPATRON" "
printf "Escriba (yes|Yes|y) :"
read  answer
case $answer in
	yes|Yes|y)
		/usr/local/bin/delfilper.pl -dir=$USERPATH -patron=$USERPATRON -dias=$USERDAY
		;;		
	*)
		echo "No se ha eliminado nada"
		exit 1
		;;
esac
