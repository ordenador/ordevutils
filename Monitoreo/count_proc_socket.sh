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
lsof -nl | grep -E "TCP|UDP" | grep $1| awk '{print $1 "; " $2}'> socket_all.txt
cat socket_all.txt | while read line; do
        echo "$line; `grep "$line" socket_all.txt | wc -l | sed 's/^[ v]*//'`" >> socket_count.txt
done
echo "COMMAND; PID; COUNT"
cat socket_count.txt | sort -t";" -k3nr | uniq
rm socket_all.txt socket_count.txt