# # lparstat
# System configuration: type=Shared mode=Uncapped smt=4 lcpu=8 mem=4096MB psize=16 ent=2.00
# %user  %sys  %wait  %idle physc %entc  lbusy  vcsw phint  %nsp  %utcyc
# ----- ----- ------ ------ ----- ----- ------ ----- ----- -----  ------
#   0.0   0.4    0.0   99.6  0.02   1.0    0.3 9482541321 17601363   101   0.58
# #
###
# nohup /home/padmin/lparstat_mon/lparstat_mon.sh &
#
cd /home/padmin/lparstat_mon
while true; do
        fecha=`date '+%F'`
        hora=`date '+%T'`
        lparstat=`lparstat 5 1| grep . | grep -Ev "configuration|-|user" | sed 's/^[ v]*//' | sed 's/[\ ] */;/g'`

        echo "${fecha} ${hora};${lparstat}" >> lparstat_${fecha}.csv
done
