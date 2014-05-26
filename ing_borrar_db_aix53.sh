#!/bin/ksh
# Funciona bien en AIX5.3 (ksh old)
## Configuracion DB
set -A validateDB wmosxdpr wmosxdhi

wmosxdpr=0
wmosxdhi=1

## Asociar DB con Filesystem, tipo AL
set -A AL
AL[wmosxdpr]="/u02/ORAARCH/wmosxdpr/"
AL[wmosxdhi]="/u02/ORAARCH/wmosxdhi/"

## Asociar DB con Filesystem, tipo DB
set -A DB
DB[wmosxdpr]="/backup/wmosxdpr/"
DB[wmosxdhi]="/backup/wmosxdhi/"

###############################################################################
## INIT
USERDB=$1
USERFS=$2
USERDAY=$3

## FUNCIONS
	listArray(){
		set -A array "$@"
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
		set -A arrayAll "$@"
		stringCompare=${arrayAll[0]}
		set -A arregloReal
		aux=0
		auxfor=0
		for i in ${arrayAll[@]}; do
			if [ $auxfor -ne 0 ]; then
				arregloReal[aux]=$i
				((aux=aux+1))
			fi
			((auxfor=auxfor+1))
		done
		# echo $stringCompare
	  	for e in "${arregloReal[@]}"; do [[ "$e" == "$stringCompare" ]] && return 0; done
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
		printf "    execas ing_borra_bd (";listArray ${validateDB[@]}; printf ") (AL|DB) <dias>\n\n"
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

	## Validar DB
	if (! containsElement ${USERDB} ${validateDB[@]} ); then
		usage
		printf "    Favor Usar Base de datos: "; listArray ${validateDB[@]}; printf "\n"
		exit 10
	fi

	## Validar TipoFS
	if [ ${USERFS} != "AL" ] && [ ${USERFS} != "DB" ] ;then
		usage
		printf "    Favor Usar Filesystems: (AL|DB)\n"
		exit 11
	fi

	## Validar <dias>
	if ( ! validateNumber ${USERDAY} );then
		usage
		printf "    Favor Usar <dias>: numeros\n\n"
		exit 12
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
