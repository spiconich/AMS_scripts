#!/bin/bash
master_cur_ip="192.168.91.146"
watcher_cur_ip="192.168.91.150"
LOGFILE=./slave.log
watcher_last_state="disconnected"
connection_flag=./connection.established
DoAmMaster=false
#
echo `date +%Y.%m.%d:%H:%M:%S` "slave script started" >> ${LOGFILE}

while [ true ]; do
  ping -q -c1 $watcher_cur_ip > /dev/null

  if [ $? -eq 0 ];
    then
      # if connected with watcher
      if  [[ "$watcher_last_state" == "disconnected" ]];
        then
          echo `date +%Y.%m.%d:%H:%M:%S` "connection to watcher established" >> ${LOGFILE}
          watcher_last_state="connected"
      fi
      # checking connection status with master
      ping -q -c1 $master_cur_ip > /dev/null
      if [ $? -eq 0 ];
        then
          # connected with watcher and master
          sleep 1
        else 
          # connected with watcher but not with master
          # checking the flags about AM connection
          if [[ -f $connection_flag ]];
          then
            #A grants that M up, nothing to do
            sleep 0
          else
            if [[ "$DoAmMaster" == "false" ]]
              then
                #A grants that M down, need to promote S
                echo `date +%Y.%m.%d:%H:%M:%S` "M is down for sure, promoting S" >> ${LOGFILE}
                DoAmMaster=true
                sudo -u postgres /usr/lib/postgresql/9.6/bin/pg_ctl promote -D /var/lib/postgresql/9.6/main
              else 
                sleep 0
             fi
          fi
       fi
    else
      # if no connection with watcher
      if  [[ "$watcher_last_state" == "connected" ]];
        then
          echo `date +%Y.%m.%d:%H:%M:%S` "connection to watcher dropped" >> ${LOGFILE}
          watcher_last_state="disconnected"
      fi
  fi
sleep 1  
done

