#!/bin/ksh
#
# Para obtener la lista de la cantidad de sockets
# por PID
#
# Para AIX, probado en 5300-12-02-1036
#
# EJEMPLO: count_proc_socket.sh ESTABLISHED
#
# Usar:
#
# LISTEN | ESTABLISHED | SYN_SENT | SYN_RECV | LAST_ACK
# CLOSE_WAIT | TIME_WAIT | CLOSED | CLOSING | FIN_WAIT1
# FIN_WAIT2
#
########################################################
if [ "$1" == "LISTEN" ] || [ "$1" == "ESTABLISHED" ] || [ "$1" == "SYN_SENT" ] || [ "$1" == "SYN_RECV" ] || [ "$1" == "LAST_ACK" ] || [ "$1" == "CLOSE_WAIT" ] || [ "$1" == "TIME_WAIT" ] || [ "$1" == "CLOSED" ] || [ "$1" == "CLOSING" ] || [ "$1" == "FIN_WAIT1" ] || [ "$1" == "FIN_WAIT2" ]
then
	lsof -nl | grep -E "TCP|UDP" | grep $1 | awk '{print $1 "; " $2}'> socket_all.txt
	touch socket_count.txt
	cat socket_all.txt | while read line; do
	        echo "$line; `grep "$line" socket_all.txt | wc -l | sed 's/^[ v]*//'`" >> socket_count.txt
	done
	echo "COMMAND; PID; COUNT"
	cat socket_count.txt | sort -t";" -k3nr | uniq
	rm socket_all.txt socket_count.txt
else  
  echo "Usar parametro: LISTEN | ESTABLISHED | SYN_SENT | SYN_RECV | LAST_ACK | CLOSE_WAIT | TIME_WAIT | CLOSED | CLOSING | FIN_WAIT1 | FIN_WAIT2"
fi