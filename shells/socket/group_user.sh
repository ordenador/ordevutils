cat /etc/group | while read line;do
        grupo=`echo $line | awk -F: '{print $1}'`
        id_grupo=`echo $line | awk -F: '{print $3}'`
        groups=`echo $line | awk -F: '{print $4}'`
        echo $grupo
        grep $id_grupo /etc/passwd |  awk -F: '{print "\t", $1}'


#este modo deja el grupo y los usuarios en la misma linea
        #echo -ne $grupo";"$groups
        #grep $id_grupo /etc/passwd | awk -F: '{print $1","}' | tr -d '\n'
        #echo ""
done
