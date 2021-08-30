#!/bin/bash

#############################################################################
#
#           Script: discovery.sh
#
#           Version: 1.0
#
#            Usage: discovery.sh [-h] [-s] [-c]
#
#      Description: This script retrieves system info from server such as
#                   hardware specs, hostname, ip, cucm imformation,
#                   uccx info, ucce info, delete rules, archiving rules
#                   along with database information
#
#          Options: run script with -h parameter to see output for flags
#                   run script with -s to start a sftp session after run
#                   run script with -c to collect cmdb which will be in the
#                     /home/admin/info(hostname)/ folder with the log file
#
#           Author: Jamie Charlton
#
#             Date: 06.12.2019
#
#        Copyright: (c) 2019 ZOOM International
#
############################################################################

#sourcing binaries and making variable for the flagging
isccx=null
iscce=null
sync=null
webadmin=/opt/callrec/etc/webadmin.xml
ldapAttr=(address port dn domain user password loginAttr firstNameAttr lastNameAttr emailAttr GroupFilterEnabled groupFilterAttribute)
uccxinf=(primaryHost primaryPort username password)
ucceInf=(ctiIPAddressA ctiPortA ctiIPAddressB ctiPortB)
hostname=$(hostname)
sniffers=/etc/callrec/sniffers.xml
writeDir=/home/admin/info_${hostname}
location=/home/admin/info_${hostname}/${hostname}_tech_discovery.log
solr=/opt/encourage/data-solr/
solr65=/opt/solr/server/solr
core=/opt/callrec/etc/core.xml
resolv=/etc/resolv.conf
integrations=/etc/callrec/integration.xml
tools=/opt/callrec/etc/tools.xml
mlm=(calls screens recd index database pvstream pvideo)
cucmInf=(name login password)
tmpfile=/tmp/temp.txt
xpSpecConf="/Configuration/SpecifiedConfiguration[@name='"
xpEqualGrp="']/EqualGroup[@name='"
xpGrp="']/Group[@name='"
xpValue="']/Value[@name='"
dvN='/dev/null'
p=p
lineDash() {
  echo ----------------------------------------------------- >>"$location"
}
line() {
  echo >> "$location"
}
callrecStatus6000() {
  "$callrecStatus" -name remoteCallRec -verbosity 5 -state all | grep recordServerCommunicator | grep ^6000 >>"$location"
}
xmlGet() {
  xpath -p "$4" "Configuration/SpecifiedConfiguration[@name='$1']/Group[@name='$2']/Value[@name='$3']" 2> /dev/null
}
rmFmt() {
  awk -F '["<>]' '{ printf("%-30s%s\n", $3":" , $5 ) }'
}
rmFmtVar() {
  awk -F '["<>]' '{ printf("%-30s%s\n", $3":" , $5 ) }'
}
rmFmt2(){
  awk -F '["<>=]' '{ printf("%-10s%-45s%-10s%-10s\n", $4":" , $6 , $11":", $13 ) }'
}
rmFmtCucm(){
  awk -F '["<>=]' '{printf("%-10s%-30s%-10s%-10s\n",  $4 ":", $6, $11 ":", $13 ) }'
}
finishWrite() {
  echo $(tput setaf 2) [DONE] $(tput sgr0)
}
xpUcce() {
  awk -F '[<>= "]' ' { print $3":", $5,"\n" $7":",$9} '
}


#create directory to store the files in for easy sftp or off transfer

if [ -d $writeDir ]; then
  echo 'Using Existing techInfo Folder'
elif [ ! -d $writeDir ]; then
  mkdir $writeDir
else
  echo "Unable to verify write directory for src info. Please verify you have permissions for directory."
  exit 0
fi


#This is just used for flagging of the command for extra features
while getopts ":hsc" opt; do
  case ${opt} in
    h)
      echo
      echo DISCOVERY SCRIPT '('$(basename "$0")')'
      echo '|-------------------------------------------------------'
      echo '| -s'
      echo '|  used to specify to use sftp after running script'
      echo '|  if you cant ping 1.1.1.1 dont waste your time'
      echo '|-------------------------------------------------------'
      echo '| -c'
      echo '|  runs cmdb if flag is specified, will put it in'
      echo '|  techinfo folder generated from script usually'
      echo '|-------------------------------------------------------'
      echo '| -h'
      echo '|  Gives you this readout '
      echo '|-------------------------------------------------------'
      echo
      exit 0
    ;;
    s)
      sftpstatus='true'
    ;;
    c)
      cmdb='true'
    ;;
    *)
      echo 'not a valid command,'
      echo 'only valid commands are -s -c -h'
      echo 'Please run -h for further information'
      exit 0
    ;;
  esac
done

echo Checking Version
fullVersion=$(rpm -q qm-meta-os --queryformat "%{VERSION}")
fullversionParse=$(rpm -q qm-meta-os --queryformat "%{VERSION}" | awk -F '[.]' ' { print $1 $2 } ' )

version=$(echo "$fullVersion" | awk -F '[.]' '{print $1}')
finishWrite

#Need to create a switch for different version in which to set the search for xpath on delete rules
case "$version" in
  6|7)
    utils="echo ls du free psql date lscpu ifconfig df cd awk grep sed cat date mkdir mv sftp xpath uptime"
    mlm2=( enabled intervalClass time onlyIfSynchronized onlyIfArchived deleteDatabase  )
    callrecStatus=/opt/callrec/bin/callrec-status
    archiveList=( taskName enabled storage maxSize deleteFiles isArchive targetDir typeClass time )
    source /opt/callrec/bin/scripts/common.sh
    #run the utils check
    checkUtils "$utils"
  ;;
  5|4)
    utils=( echo ls du free psql date lscpu ifconfig df cd awk grep sed cat date mkdir mv sftp xpath uptime )
    for util in "${utils[@]}"
      do
      exist=$(command -v "$util")
      if [ $exist ]; then
        echo "$exist present" >> /tmp/discovery.log
      else
        echo "$util is missing"
        exit 0
      fi 
    done
    mlm2=( enabled intervalClass time onlyIfSynchronized onlyIfBackuped deleteDatabase )
    callrecStatus=/opt/callrec/bin/callrec_status
    archiveList=( taskName enabled maxSize deleteFiles isArchive TargetDir typeClass time )
  ;;
  *)
    exit 0
  ;;
esac
#get callrec version and note when info was gathered
echo INFORMATION WAS GATHERED ON: >"$location"
date >>"$location"
echo CALLREC VERSION: $fullVersion >>"$location"
echo >>"$location"

#check networking info and write to file
echo "Getting Network Info"
echo NETWORK INFO: >>"$location"
lineDash
echo HOSTNAME: $hostname >>"$location"
echo >>"$location"
echo DNS SERVER: $( grep nameserver $resolv | awk -F " " ' { print $2} ' ) >>"$location"
finishWrite
echo "Checking postfix relay hosts"
postconf relayhost >>"$location"
finishWrite
echo >>"$location"

echo NETWORK SETUP INFORMATION: >>"$location"
ifconfig | grep 'Link\|inet' >>"$location"
echo >>"$location"
echo >>"$location"

#write cpu info
echo "Getting Cpu Info"
echo CPU INFO: >>"$location"
lineDash
uptime >>"$location"
case "$version" in
  5|6|7)
    lscpu | grep -v "Flags" >>"$location"
  ;;
  4)
    cat /proc/cpuinfo >>"$location"
  ;;
esac
echo >>"$location"
finishWrite

#write memory info
echo "Getting Memory Info"
echo MEMORY: >>"$location"
lineDash
free -m >>"$location"
echo >>"$location"
finishWrite
echo >>"$location"

#write storage info
echo "Getting Storage Info"
echo STORAGE: >>"$location"
lineDash
case "$version" in
  6|7)
    df -h --output=source,size,used,avail >>"$location"
  ;;
  4|5)
    df -H >>"$location"

  ;;
  *)
    echo 'No version detected'
    exit 0
  ;;
esac
finishWrite
echo >>"$location"

#check all services set to run
echo "Getting Enabled Services"
echo Enabled Services: >>"$location"
lineDash
case "$version" in
  6|7)
    qm-services >>"$location"
  ;;
  4|5)
    grep '="1"' /opt/callrec/etc/callrec.conf | awk -F '[_=]' '{print $2}' >>"$location"
  ;;
esac
finishWrite
echo >>"$location"

#write info for concurrent calls max
echo "Checking License Info"
echo LICENSE: >>"$location"
lineDash
case "$version" in
  6|7)
    "$callrecStatus" -state all -verbosity 5 | grep 20001 | awk -F " - " ' {print $2}' >>"$location"
    echo >>"$location"
    echo 'Checking Recorder Status if Present':
    echo RECORDER STATUS: >>"$location"
    callrecStatus6000

  ;;
  4|5)
    "$callrecStatus" -name remoteCallRec -verbosity 5 -state all | grep "2000[1-2][0-9]" | awk -F " - " ' {print $2}' >>"$location"
    echo >>"$location"
    echo 'Checking Recorder Status if Present':
    echo RECORDER STATUS: >>"$location"
    callrecStatus6000

  ;;
esac
finishWrite
echo >>"$location"

#write info related to call space/usage and amount
echo "Getting Average Daily Usage Information"
echo "AVERAGE DAY:" >>"$location"
lineDash
psql -U postgres callrec -c "SELECT date_trunc('day', start_ts), count(*) FROM couples WHERE start_ts >= CURRENT_TIMESTAMP - 5 * interval '1 day' GROUP BY date_trunc('day', start_ts);" >>"$location"
finishWrite
echo >>"$location"

#were going to go get the mlm delete info in xml, and chop it up real good with some sed and some awk, it'll be great! trust me
echo "Getting Data Retention Info"
echo MLM DELETE INFO: >>"$location"

for mlmA in "${mlm[@]}"
do
  lineDash
  echo $mlmA >> "$location"
  lineDash
  for mlmB in "${mlm2[@]}"
  do
    xmlGet delete "$mlmA" "$mlmB" "$tools" | rmFmt >> $location
  done
done
echo >>"$location"

#archiving information
echo "Getting Archiving Info"
line
echo "Archiving Info" >> $location
lineDash
loopnum=1
totalEnt=$(xpath -p "$tools" ${xpSpecConf}archive${xpEqualGrp}archiveUnit${xpValue}${archiveList[0]}"'"  2> $dvN | grep -o ${archiveList[0]} | wc -l )
if [ $totalEnt -gt "0" ]; then
  for info in "${archiveList[@]}"
    do
    arcIn=${xpSpecConf}archive${xpEqualGrp}archiveUnit${xpValue}${info}"'"]
    entrynum=$(xpath -p "$tools" $arcIn 2> $dvN | grep -o \"$info\" | wc -l)
    startClm1=4
    startClm2=6
    tmpCounter=1
    while [ $tmpCounter -le "$entrynum" ];
      do
      xpath -p "$tools" $arcIn 2> /dev/null | awk -F '["<>=]' " { printf( \"%-20s%-30s\n\", \$$startClm1 , \$$startClm2 ) } " >> $tmpfile
      startClm1=$(( startClm1 + 7 ))
      startClm2=$(( startClm2 + 7  ))
      tmpCounter=$(( tmpCounter + 1 ))
    done
  done
  if [ "$totalEnt" -eq "1" ]; then
    cat $tmpfile >> $location
  else
    while [ $loopnum -le $totalEnt ];
      do
      sed -n "${loopnum}~${totalEnt}${p}" $tmpfile >> $location
      loopnum=$(( $loopnum + 1 ))
      lineDash
    done
  fi
  cat $tmpfile >> /tmp/temp2.txt
  rm -f $tmpfile
else
  echo "No Archving in Use"
  echo "No Archving in Use" >> $location
fi

line

#check to make sure ldap is not default and if it isnt then
echo 'Checking LDAP'
echo LDAP INFO: >>"$location"
lineDash
ldapInf=$( xpath -p $webadmin ${xpSpecConf}ldap${xpEqualGrp}ldapServer${xpValue}address"'"] 2> $dvN | awk -F '["<>]' ' { print $5 } ' )
if [ "$ldapInf" == 'ldap.mydomain.net' ]; then
  echo LDAP not in use
  echo LDAP NOT IN USE >>"$location"
else
  echo LDAP In Use
  for ldapAttr in "${ldapAttr[@]}"
  do
    xpath -p $webadmin ${xpSpecConf}ldap${xpEqualGrp}ldapServer${xpValue}$ldapAttr"'"] 2> $dvN | rmFmt >> "$location"
  done
fi

#CUCM login, ip and password
echo "Getting Basic CUCM Information"
echo >>"$location"
echo CUCM info: >>"$location"
lineDash
loopNum=1
cuEnt=$( xpath -p $sniffers ${xpSpecConf}jtapi${xpEqualGrp}sniffer${xpGrp}provider${xpValue}${cucmInf[1]}"'"] 2> $dvN | grep -o ${cucmInf[1]} | wc -l )
for info in "${cucmInf[@]}"
  do
  cucIn=${xpSpecConf}jtapi${xpEqualGrp}sniffer${xpGrp}provider${xpValue}${info}"'"]
  entrynum=$(xpath -p $sniffers $cucIn 2> /dev/null | grep -o \"$info\" | wc -l)
  startClm1=4
  startClm2=6
  tmpCounter=0
  while [ $tmpCounter -le "$entrynum" ];
    do
    xpath -p $sniffers $cucIn 2> /dev/null | awk -F '["<>=]' " { printf( \"%-10s%-30s\n\", \$$startClm1 , \$$startClm2 ) } " >> $tmpfile
    startClm1=$(( startClm1 + 7 ))
    startClm2=$(( startClm2 + 7  ))
    tmpCounter=$(( tmpCounter + 1 ))
  done
done
if [ $cuEnt == "1" ]; then
  cat $tmpfile >> $location
else
  while [ $loopNum -le $cuEnt ];
    do
    sed -n "${loopNum}~${tmpCounter}${p}" $tmpfile >> $location
    loopNum=$(( $loopNum + 1 ))
    lineDash
  done
fi
rm -f $tmpfile
finishWrite
echo >>"$location"

#Integrations
echo "Getting Integration Info"
echo >>"$location"
echo "Integrations Info:" >>"$location"
lineDash

#Check For UCCE
case $version in
6|7)
  ucce="$(systemctl is-enabled callrec-ucce)"
  if [ "$ucce" == "enabled" ]; then
    iscce=true
  else
    iscce=false
  fi
  ;;
4|5)
  ucce=$(grep RUN_IPCC /opt/callrec/etc/callrec.conf)
  if [ "$ucce" != 'RUN_IPCC="0"' ]; then
    iscce=true
  else
    iscce=false
  fi
;;
esac
if [ "$iscce" = true ];then 
  echo "UCCE is in use"
  echo "UCCE Information" >>"$location"
  lineDash
  for ucceIn in "${ucceInf[@]}"
  do
    xpath -p "$integrations" ${xpSpecConf}ipcc${xpEqualGrp}ipcc${xpEqualGrp}cti${xpValue}$ucceIn"'"] 2> /dev/null | rmFmt >> $location
  done
  line
  echo "AWDB Information" >>"$location"
  lineDash
  xpath -p $core "/Configuration/Database/Pool[@name='awdb']/Url" 2> /dev/null | xpUcce >> $location
  xpath -p $core "/Configuration/Database/Pool[@name='awdb']/Login" 2> /dev/null | xpUcce >> $location
  line
else
  echo NO UCCE INTEGRATION >>"$location"
  echo >>"$location"
  echo 'No UCCE Integration'
fi

#Check For UCCX
case $version in
6|7)
  uccx="$(systemctl is-enabled callrec-uccx)"
  if [ "$uccx" == "enabled" ]; then
    isccx=true
  else
    isccx=false
  fi
;;
4|5)
  ccx_enabled=$(grep RUN_IPCCEX /opt/callrec/etc/callrec.conf)
  if [ "$ccx_enabled" != 'RUN_IPCCEX="0"' ]; then
    isccx=true
  else
    isccx=false
  fi
;;
esac

if [ "$isccx" == true ]; then
  echo "UCCX Is In Use, Getting UCCX Info"
  echo "UCCX Server Information" >>"$location"
  lineDash
  for uccxIn in "${uccxinf[@]}"
    do
      xmlGet ipccex uccx "$uccxIn" "$integrations" | rmFmt >> $location
    done
else
  echo NO UCCX INTEGRATION >>"$location"
  echo 'No UCCX Integration'
fi
echo >>"$location"
finishWrite

#write /usr/bin/psql db info
echo "Getting DB info"
echo DATABASE INFORMATION: >>"$location"
lineDash
echo 'Active Users In SC'
echo SC ACTIVE USERS: $(psql -AtU postgres callrec -c "SELECT count(*) from sc_users where status='ACTIVE'" ) >>"$location"
echo 'Checking If User Accounts are Synced'
sync=$(psql -t -U postgres callrec -c "select count(*) from sc_users where database !=1 ;")
if [ $sync != 0 ]; then
  echo USER SYNC IN USE IN SC >>"$location"
else
  echo USERS SYNC NOT IN USE IN SC >>"$location"
fi
case "$version" in
  6|7)
    echo 'Checking Size of Solr'
    if [ $fullversionParse -ge "65" ]; then
      echo SOLR DATABASE SIZE: $(du -ch $solr65 | tail -n 1) >>"$location"
    else
      echo SOLR DATABASE SIZE: $(du -ch $solr | tail -n 1) >>"$location"
      echo >>"$location"
    fi
  ;;
  5|6)
    echo NO SOLR IN $version .x SKIPPING CHECK
  ;;
esac
echo >>"$location"
echo $(which psql) ENTRIES: >>"$location"
lineDash
psql -U callrec -c "SELECT schemaname,relname,n_live_tup as count
    FROM pg_stat_user_tables
ORDER BY n_live_tup DESC;" >>"$location"
echo >>"$location"
echo SIZE OF PSQLDB>>"$location"
lineDash
psql -U postgres -c " SELECT pg_size_pretty( pg_database_size('callrec') );" >> "$location"
finishWrite
echo >>"$location"

#run cmdb and write it to that folder
if [ "$cmdb" ]; then
  echo "Running CMDB"
  /opt/callrec/bin/scripts/cmdb.sh -d $writeDir
  echo "Compressing Info Folder"
  tar -czvf info_$(hostname)_$(date +"%m%d%y").gz /home/admin/info_$hostname/
fi

#handles the sftp declared by flag
if [ "$sftpstatus" ]; then
  echo "Enter Username "
  read username
  sftp "$username"@file.zoomint.com
fi