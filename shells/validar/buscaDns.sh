#!/usr/bin/ksh
# Usar: buscaDns.sh servidor
#       cat nodos.txt | while read line; do buscaDns.sh $line; done
total=0
nodo=$1
nodoaux=$nodo
salida="salida_dns.txt"
prefix="r"
set -A suffix _cdlv _rosas _le _gtd -cdlv -rosas -le -gtd

llamaDns(){
	NSLOOKUP_VALIDA=`nslookup $nodoaux | grep -v ***REMOVED***.cl | grep -v 108.0.1.45 | grep Address | awk '{print $2}' | sed '/^$/d' | wc -l | sed 's/^[ v]*//'`
	if [ "$NSLOOKUP_VALIDA" != "0" ]; then
		NSLOOKUP=`print $nodoaux"\t";nslookup $nodoaux | grep -v ***REMOVED***.cl | grep -v 108.0.1.45 | grep Address | awk '{print $2}' | sed 's/^[ v]*//' |  tr -d '\n'`
		echo $NSLOOKUP >> $salida
		echo $NSLOOKUP
	fi
}

# Verifica el nodo sin sufijo ni prefijo
llamaDns

# Verifica prefijo+nodo
nodoaux=$prefix$nodo
llamaDns

# Verifica nodo+sufijo
for i in ${suffix[@]}; do
	nodoaux=$nodo$i
	llamaDns
done