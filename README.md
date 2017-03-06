# autodump

Autodump is shell script usefull to collect pcap dumps & log files from distributed systems. It has been created primary for Mavenir mOne platform but can be useful for any other systems as well.

## Main features are:
 - written on bash, no other software is required
 - support tshark or tcpdump or any other custom tool
 - flexible & customizable configuration
 - for Mavenir mOne platform: this tool detects which cards in ACTIVE state and captures traffic only from active cards. You don't need to care from which CE/MP/RM you need to captrure traffic
 - for Mavenir mOne platform: all CE/MP/RM host are accessible through AM card, so you don't need direct connection to internal fabric or base interfaces

## Install
1. download archive
2. unzip it

### Prerequisite
- bash
- ssh
- tcpdump OR tshark on hosts where you're going to capture trafic
- your ssh key must stored on all hosts that you're going to capture

## Configure
Edit file autodump_v2.cfg:

1. populate AM array with neccessary mOne products and user@hostname, like:
 AM[uag]="root@uag"
where:  
uag - product name (unique)
root@uag - user@hostname as ssh parameter, hostname can be ip address here
Please note, hostname - define here Virtual IP of AM cards (OAM) or IP one of the AM card which is running now.

2. populate hosts array with regular hosts data, like:
hosts[pcrf]="root@pcrf"
where: 
pcrf - product name (unique)
root@pcrf - user@hostname, hostname can be ip address here

3. populate commands to capture pcap data from mOne hosts, like:
commands_pcap_da[uag-RM]
where "uag-RM" is:
uag - product name defined in AM array
RM - card type, returned by readShm command
Please note: command you're defining should send all data to stdout

4. populate commands to capture mlog data from mOne hosts:
commands_mlogc_da[uag-AM]
here the logic is the same as for pcap data
Please note: command you're defining should send all data to stdout

5. define commands for regular (non-mOne) hosts:
commands_pcap[pcrf]
where pcrf - product name defined in "hosts" array
Please note: command you're defining should send all data to stdout

6. check for temporary dir to store pcap and mlog data
there are two parameters: 
pcap_local_store_dir
mlogc_local_store_dir
by default they has defined as '/data/storage/'. So you need to have /data/storage/ folders on all hosts where you're going to capture data from.

## Usage
1. once you have prepared the autodump_v2.cfg file, now you can run autodump_v2.sh script
2. run it: ./autodump_v2.sh
3. if your hosts are accessible and there is no errors in configuration, then you'll see the following lines:
```
stop terminal windows when done
press Enter to stop
```
and then depending on number of hosts configured you'll see several lines and counters like:
```
Capturing on Pseudo-device that captures on all interfaces
Capturing on Pseudo-device that captures on all interfaces
Capturing on Pseudo-device that captures on all interfaces
91  
```
This means tcpdump/tshark is started. Now you can run your test, all traffic is capturing.

4. as soon as you'll done your test, press ENTER. Don't use CTRL-C!

5. now capturing is stopped and files transfer to local PC is started. You'll get all files in folder like 2017_03_06_14_42_53, where the first three numbers are year,month,day and the following ones are hour, minutes and seconds.

6. Enjoy your trace using wireshark tool

## Advanced Usage
TBD

## References
You may also like [pcap2uml](https://github.com/dgudtsov/pcap2uml) tool to visualize your trace.

