#
# $1: usuario
# $2: lista_nodos.txt
#
CMD_SSH="ssh -o PasswordAuthentication=no -n"

if [ ${#} -ne 2 ]
then
        echo "Shell sirve para crear un usuario nuevo a un listado de maquinas"
        echo "Solo lo crea si existe previamente algun usuario del mismo grupo.\n"
        echo "Usar:"
        echo "user_linux.sh usuario lista_nodos.txt"
        exit 255
fi

>tmp/lista.tmp
>tmp/userini.tmp

group=`cat /etc/passwd | grep $1 | awk -F: '{ print $4}'`
users_group_exist=0

cat $2 | while read line;do
        users_group_exist=`$CMD_SSH $line grep -c :$group: /etc/passwd`
        if [[ $users_group_exist -gt 0 ]]; then
                echo $line >> tmp/lista.tmp
        fi
done

cat tmp/lista.tmp | while read line;do echo "maq:"$line":ssh" >> tmp/userini.tmp;done
userrep.pl --ini=tmp/userini.tmp --usr=$1 --prgrep --profile
