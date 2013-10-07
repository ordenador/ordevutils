#!/usr/bin/ksh
#Vars
cuenta=0
CMD_SSH="ssh -n -o PasswordAuthentication=no"
LOGS="salida_cambio_hora.txt"
zona_chile_ver='CLST'
zona_chile_inv='CLT'
FECHA=`date +"%d%m%y"`
NODOS_LINUX="nodos_linux.txt"
echo "La fecha es: ${FECHA}"
cuenta=`cat ${NODOS_LINUX} | wc -l`
echo "Son: "$cuenta" Maquinas"
cuenta=$(( cuenta - 0 ))
while [ $cuenta -ge  1 ]; do
  line=`cat ${NODOS_LINUX} | tail -${cuenta} |head -1`
  echo $line
  os=`${CMD_SSH} ${line} uname -s`
  if [ $os = "Linux" ]; then
      zona_maquina=`${CMD_SSH} ${line} date +"%Z"`
      if [ $zona_chile_ver = $zona_maquina ] || [ $zona_chile_inv == $zona_maquina ]; then
        echo "La maquina ${line} Tiene zona horaria ${zona_maquina}, SI se hace cambio" >> $LOGS
            echo $line
            echo $line >> $LOGS
            $CMD_SSH $line cp /usr/share/zoneinfo/America/Santiago /usr/share/zoneinfo/America/Santiago.ori.$FECHA
            $CMD_SSH $line ls -ltr /usr/share/zoneinfo/America/Santiago.ori*
            scp hora_2013.txt $line:/root
            $CMD_SSH $line zic /root/hora_2013.txt
            $CMD_SSH $line mv /etc/localtime /etc/localtime.ori.$FECHA
            $CMD_SSH $line "ls -ltr /etc/localtime.ori.$FECHA" >> $LOGS
            $CMD_SSH $line ln -s /usr/share/zoneinfo/America/Santiago /etc/localtime
            $CMD_SSH $line ls -ltr /etc/localtime >> $LOGS
            $CMD_SSH $line zdump -v /etc/localtime | grep 2013 >> $LOGS
      else
        echo "La máquina ${line} NO tiene zona horaria CLST o CLT, NO se hace cambio" >> $LOGS
        echo "Tiene Zona Horaria: ${zona_maquina}" >> $LOGS
      fi
  else
    echo "La maquina ${line} no es Linux o no es posible conectarse, NO se hace cambio" >> $LOGS
  fi
  echo Fin >> $LOGS
  cuenta=$(( cuenta - 1 ))
done
