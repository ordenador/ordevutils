#!/bin/sh

PATHFILES=$*
PS3="Seleccione el archivo para ver o 'CTRL+C' para salir: "
LIST=$(ls -l $PATHFILES | awk '{print $NF}')

echo "--------------------------------"
echo "--  Lista de logs             --"
echo "--------------------------------"

select p in $LIST; do
        echo ""
        echo "Elija la opción"
        echo "  m.-     more"
        echo "  t.-     tail -500"
        echo ""
        printf "Escriba (m|more o t|tail):"
        read answer
        case $answer in
                m|more)
                        more $p
                        ;;
                t|tail)
                        tail -500 $p
                        ;;
                *)
                        echo "  Error en ingreso de parametro"
                        echo "  Opciones validas: m|more|t|tail"
                        echo ""
                        exit 1
                        ;;
        esac

    break
done
