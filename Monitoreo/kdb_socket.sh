#!/bin/ksh
#
# Mapeo de socket a process ID
#
# Para AIX, probado en 5300-12-02-1036
#
# EXAMAPLE EXEC: kdb_socket.sh f1006000645f2399
#
# f1006000645f2399 es "PCB/ADDR" 
# Obtenido del primer parámetro comando: netstat -Aan
#
#####################################################
echo "sockinfo $1 tcpcb" > socket_script.kdb
echo "quit" >> socket_script.kdb
kdb -script -c "socket_script.kdb"
rm socket_script.kdb
