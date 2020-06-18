#!/bin/bash

slave_ip="192.168.91.148"
watcher_ip="192.168.91.150"
logfile=./master.log
master_status=open
echo `date +%Y.%m.%d:%H:%M:%S` ' master script started ' >> ${logfile}

while [ true ]; do
  if [[ "$master_status" == "open" ]];
    then
      ping -q -c1 $slave_ip > /dev/null
      if [ $? -eq 0 ];
        then
          #connected with slave
          sleep 0
        else
          #not connected with slave
          ping -q -c1 $watcher_ip > /dev/null
          if [ $? -eq 0 ]; 
            then
              #not connected with slave but connected with A
              sleep 0
            else
               #not connected with slave and A
               echo `date +%Y.%m.%d:%H:%M:%S` 'not connected with S and A, closing ports...' >> ${logfile}
               master_status=closed
               sudo iptables -A INPUT -p tcp --dport 5432 -j DROP
               sudo iptables -A INPUT -p tcp --sport 5432 -j DROP
               sudo iptables -A OUTPUT -p tcp --dport 5432 -j DROP
               sudo iptables -A OUTPUT -p tcp  --dport 5432 -j DROP
          fi
          
      fi 
  fi
  #checking if connection returned and restoring iptables
  if  [[ "$master_status" == "closed" ]]
    then
      ping -q -c1 $slave_ip > /dev/null
      if [ $? -eq 0 ];
        then
          #connected with slave
          #restoring iptables
          master_status=open
          sudo iptables -D INPUT 1
          sudo iptables -D INPUT 1
          sudo iptables -D OUTPUT 1
          sudo iptables -D OUTPUT 1
          sudo iptables -A INPUT -p tcp --dport 5432 -j ACCEPT
          sudo iptables -A INPUT -p tcp --sport 5432 -j ACCEPT
          sudo iptables -A OUTPUT -p tcp --sport 5432 -j ACCEPT
          sudo iptables -A OUTPUT -p tcp --dport 5432 -j ACCEPT
          echo `date +%Y.%m.%d:%H:%M:%S` 'restoring ip tables (connected with S)' >> ${logfile}
        else
          #checking if connected with A ( not connected with S )
          ping -q -c1 $watcher_ip > /dev/null
          if [ $? -eq 0 ];
            then
              #connected with watcher, restoring ip tables
              master_status=open
              sudo iptables -D INPUT 1
              sudo iptables -D INPUT 1
              sudo iptables -D OUTPUT 1
              sudo iptables -D OUTPUT 1
              sudo iptables -A INPUT -p tcp --dport 5432 -j ACCEPT
              sudo iptables -A INPUT -p tcp --sport 5432 -j ACCEPT
              sudo iptables -A OUTPUT -p tcp --sport 5432 -j ACCEPT
              sudo iptables -A OUTPUT -p tcp --dport 5432 -j ACCEPT
              echo `date +%Y.%m.%d:%H:%M:%S` 'restoring ip tables (connected with A)' >> ${logfile}
          fi
      fi
     
  fi
done

