#/bin/bash
#
# Autor: Mario Faundez(Ordenador, mariofaundez@hotmail.com)
#
while true; do
        ##LISTEN
        touch LISTEN.txt
        lsof -nlP | grep -E "TCP|UDP" | grep LISTEN | awk '{print $8}' > LISTEN_tmp.txt
        cat LISTEN.txt >> LISTEN_tmp.txt
        cat LISTEN_tmp.txt | sort | uniq > LISTEN.txt

        ##ESTABLISHED
        touch ESTABLISHED.txt
        lsof -nlP | grep -E "TCP|UDP" | grep ESTABLISHED | awk '{print $8}' | while read line;do
        ORIGEN=`echo $line | awk -F '->' '{print $1}' | awk -F: '{print $1";"$2}'`
        DESTINO=`echo $line | awk -F '->' '{print $2}' | awk -F: '{print $1";"$2}'`
        printf $ORIGEN';'
        echo $DESTINO
        done > ESTABLISHED_tmp.txt
        cat ESTABLISHED.txt >> ESTABLISHED_tmp.txt
        cat ESTABLISHED_tmp.txt | sort | uniq > ESTABLISHED.txt

        sleep 30
done
