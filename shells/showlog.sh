#!/bin/sh

PATHFILES=$*
PS3="Seleccione el archivo para ver o 'CTRL+C' para salir: "
LIST=$(ls -l $PATHFILES | awk '{print $NF}')

echo "--------------------------------"
echo "--  Lista de logs             --"
echo "--------------------------------"

select p in $LIST; do
    more $p
    break
done
