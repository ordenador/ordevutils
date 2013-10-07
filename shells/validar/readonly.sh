echo $1
ssh $1 "cat /etc/fstab | egrep -v 'swap|var|usr|home|tmp|opt|/boot|tmpfs|devpts|sysfs|#|proc' | awk '{print $2}' | while read line ;do touch $line'/lolo';rm $line'/lolo';done"
echo ""
