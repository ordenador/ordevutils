## USAR:
##
## nohup /root/rsync-u01-to-new_u01.sh &
##
while true; do
        rsyncProcs=$( ps -fea | grep -w 'rsync' | grep -v grep | wc -l )
        if [ $rsyncProcs -gt 0 ]; then
                echo "existe un procesos rsync ya corriendo"
        else
                rsync -va --delete /u01/home/ /new_u01/home/
        fi
        sleep 600
done
