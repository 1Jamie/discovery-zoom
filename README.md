# discovery script

discovery.sh script designed to pull information off of zoom callrec servers

Supports 4x 5x 6x and 7x boxes

-h shows help command

-c pulls the system cmdb while running

-s starts sftp after running

For any issues with the script, please email me at jamie.charlton@eleveo.com
and I will work on fixing the issue as soon as I can

# Example Output


```
INFORMATION WAS GATHERED ON:
Mon Aug 30 15:19:26 CDT 2021
CALLREC VERSION: 7.0.0

NETWORK INFO:
-----------------------------------------------------
HOSTNAME: test.elveo.information

DNS SERVER: 192.x.x.x
relayhost = 192.x.x.x

NETWORK SETUP INFORMATION:
        inet 192.x.x.x  netmask 255.255.255.0  broadcast 192.x.x.x
        inet 127.0.0.1  netmask 255.0.0.0


CPU INFO:
-----------------------------------------------------
 15:19:26 up 34 days, 21:16,  2 users,  load average: 0.13, 0.15, 0.10
Architecture:          x86_64
CPU op-mode(s):        32-bit, 64-bit
Byte Order:            Little Endian
CPU(s):                4
On-line CPU(s) list:   0-3
Thread(s) per core:    1
Core(s) per socket:    2
Socket(s):             2
NUMA node(s):          1
Vendor ID:             GenuineIntel
CPU family:            6
Model:                 85
Model name:            Intel(R) Xeon(R) Gold 5118 CPU @ 2.30GHz
Stepping:              4
CPU MHz:               2294.609
BogoMIPS:              4589.21
Hypervisor vendor:     VMware
Virtualization type:   full
L1d cache:             32K
L1i cache:             32K
L2 cache:              1024K
L3 cache:              16896K
NUMA node0 CPU(s):     0-3

MEMORY:
-----------------------------------------------------
              total        used        free      shared  buff/cache   available
Mem:          15885        8575        3026          24        4283        6955
Swap:          2047           0        2047


STORAGE:
-----------------------------------------------------
Filesystem                   Size  Used Avail

(parition and storage information along with nfs mounts will be shown here)

Enabled Services:
-----------------------------------------------------
== QM services ==

(services will be displayed here if they are enabled in systemd or in the config file fpr 5x and 4x systems)

LICENSE:
-----------------------------------------------------
License number ... 20xxxxxxxxxxxx
Licensed to ... Someone
Major license state ... callrec.license, NOT ACTIVATED ............................................. [ WARN ]
...... more information partaining to license will be here 

RECORDER STATUS:
6000005   [recordServerCommunicator]    [*....] - License access ... true ............................................................................ [  OK  ]
6000006   [recordServerCommunicator]    [*....] - Licensed max count of recorded calls ... 5 (10 streams); warn 5(10)
6000011   [recordServerCommunicator]    [**...] - Count of recording streams, max recording streams, max requested streams ... 0, 0, 0
6000007   [recordServerCommunicator]    [*....] - Count of not recorded streams because of licensing (max recording calls) ... 0
6000010   [recordServerCommunicator]    [*....] - Count of recorders (RS, SLR) ... 0, 1

AVERAGE DAY:
-----------------------------------------------------
 date_trunc | count 
------------+-------
(0 rows)
(will show average calls for last week if information is present)

MLM DELETE INFO:
-----------------------------------------------------
calls
-----------------------------------------------------
(config will be shown here for this setting)

-----------------------------------------------------
screens
-----------------------------------------------------
(config will be shown here for this setting)

-----------------------------------------------------
recd
-----------------------------------------------------
(config will be shown here for this setting)

-----------------------------------------------------
index
-----------------------------------------------------
(config will be shown here for this setting)

-----------------------------------------------------
database
-----------------------------------------------------
(config will be shown here for this setting)

-----------------------------------------------------
pvstream
-----------------------------------------------------
(config will be shown here for this setting)

-----------------------------------------------------
pvideo
-----------------------------------------------------
(config will be shown here for this setting)


Archiving Info
-----------------------------------------------------
No Archving in Use
(archive details and frequency will be shown here if configured)

LDAP INFO:
-----------------------------------------------------
LDAP NOT IN USE

(ldap adress, user...etc will be show here if enabled)

CUCM info:
-----------------------------------------------------
name      192.x.x.x                                            
login     ccmtestuser                                                       
password  admin                 
(this will show cucm setup information )                      

Integrations Info:
-----------------------------------------------------

UCCe Server Information
-----------------------------------------------------
(cti address and awdb information will be displayed here)

UCCX Server Information
-----------------------------------------------------
(primary host, username and password will be displayed here)

DATABASE INFORMATION:
-----------------------------------------------------
SC ACTIVE USERS: 4
USERS SYNC NOT IN USE IN SC
SOLR DATABASE SIZE: 436K total
(shows size of solr db if present, and will show if there is a user sync being done to ccx or cce)

/bin/psql ENTRIES:
-----------------------------------------------------
 schemaname |           relname           | count 
------------+-----------------------------+-------
 callrec    | SCHEMA_UPDATES              |   507
(information about entires in database will be shown here listed in count order with relname. information
reduced so its not unweildly in example)
(83 rows)


SIZE OF PSQLDB
-----------------------------------------------------
 pg_size_pretty 
----------------
 10 MB
(1 row)
(shows size of database on system)
```
