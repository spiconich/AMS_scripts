#!/bin/bash
slave_cur_ip="192.168.91.148"
master_cur_ip="192.168.91.146"
LOGFILE=./watcher.log
ssh_slave_user="postgres"
#
#ssh postgres@${slave_cur_ip} '>> /var/lib/postgresql/postgres_goods/test.flag'
echo  `date +%Y.%m.%d:%H:%M:%S` "Arbiter script started" >> ${LOGFILE}

master_cur_conn_status=connected

while [ true ]; do
  ping_succ=0
  ping_attempt=0
  for ping_attempt in "1st" "2nd" "3rd" "4th"
  do
    ping -q -c 1 $master_cur_ip > /dev/null

    if [ $? -eq 0 ]; 
      then
      let  "ping_succ++" 
    fi
  done
  if (( "$ping_succ" <2 )) && [[ "$master_cur_conn_status" == "connected" ]]
    then ssh ${ssh_slave_user}@${slave_cur_ip} '>> /var/lib/postgresql/postgres_goods/connection.dropped'
    ssh ${ssh_slave_user}@${slave_cur_ip} 'rm -f /var/lib/postgresql/postgres_goods/connection.established'
      echo `date +%Y.%m.%d:%H:%M:%S` "connection to master dropped" >> ${LOGFILE}
      master_cur_conn_status="disconnected"
    else
      if (( "$ping_succ" >2 )) && [[ "$master_cur_conn_status" == "disconnected" ]]
        then ssh ${ssh_slave_user}@${slave_cur_ip} '>> /var/lib/postgresql/postgres_goods/connection.established'
        echo `date +%Y.%m.%d:%H:%M:%S` "connection to master established" >> ${LOGFILE}
      master_cur_conn_status="connected"
    ssh ${ssh_slave_user}@${slave_cur_ip} 'rm -f /var/lib/postgresql/postgres_goods/connection.dropped'
      fi
  fi
done
echo `date +%Y.%m.%d:%H:%M:%S` "Arbiter script stopped" >> ${LOGFILE}

