#!/bin/bash
#
# Author:	Wei.Lu (wei.w.lu@oracle.com)
# Date: 	May 9th, 2013
#
# function valid_ip is from http://www.linuxjournal.com/content/validating-ip-address-bash-script

<<TIPS
1, You can't blame me if you found OSA boot don't work, it's most likely you don't have an OSA installed!
2, make sure the network is working
3, the default user@password is root@changeme
4, the cmd is case INSENSITIVE, you can input bios/Bios/BIOS/F2/f2 as you like
5, default timeout for reboot is 10 minutes, you can change it with -t before -U and -P
6, if you don't want to reboot the system now, user -r switch(and maybe you should use -t as well)
7, default is F8, and the simplist way to use is #script.sh spip OR #script.sh spip bios etc.
8, feel free to comment!
TIPS

DEFAULT_TIMEOUT=600

while getopts "hrt:U:P:" opt
do
        case $opt in
                r ) NO_REBOOT="1";;
                t ) TIME_OUT=$OPTARG;;
                U ) USR=$OPTARG;;
                P ) PASSWORD=$OPTARG;;
		h|? ) echo -e "\033[33m A script to reboot system and press Fn for you. \033[0m"
		    echo -e "\033[33m usage: script_name.sh [-r] [-ttimeout] [-Uuser] [-Ppassword] spip [cmd] \033[0m"
		    echo -e "\033[33m        where cmd can be one of the followings \033[0m"
		    echo -e "\033[33m        f2, bios \033[0m"
		    echo -e "\033[33m        f8, menu \033[0m"
		    echo -e "\033[33m        f9, osa \033[0m"
		    echo -e "\033[33m        f12, pxe \033[0m"
		    exit 0;;
        esac
done
shift $(($OPTIND - 1))
IP=$1
shift 1
CMD=$*

#validate variables
if [[ "$USR" -ne "root" && ! -z "$USR" ]]
then
	echo -e "\033[31m You should login SP with root instead of \"$USR\"! \033[0m"
	exit 1
else
	USR="root"
fi
if [ -z "$PASSWORD" ]
then
	PASSWORD="changeme"
fi
if [ -z "$TIME_OUT" ]
then
	TIME_OUT=$DEFAULT_TIMEOUT
fi
CMD3=""
if [ -z "$NO_REBOOT" ]
then
	CMD3="reset -script /SYS\r"
fi

CMD2="f8"
if [ -z "$CMD" ]
then
	CMD="f8"
fi
case "$CMD" in 
	[fF]2|[Bb][Ii][Oo][Ss])	CMD2="f2"	;;
	[fF]8|[Mm][Ee][Nn][Uu])	CMD2="f8"	;;
	[fF]9|[Oo][Ss][Aa])	CMD2="f9"	;;
	[fF]12|[Pp][Xx][Ee])	CMD2="f12"	;;
	*) echo -e "\033[31m invalid command, available commands are F2,F8,F9,F12 OR bios,menu,osa,pxe! \033[0m"
					exit 5		;;
esac

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

if ! valid_ip $IP
then
	echo -e "\033[31m IP format invalid, exiting! \033[0m"
	exit 2
fi

ssh-keygen -R $IP > /dev/null 2>&1

#reboot and press Fn
/usr/bin/expect -c '
set reboot_time "'"$TIME_OUT"'"
set user "'"$USR"'"
set password "'"$PASSWORD"'"
set ip "'"$IP"'"
set cmd "'"$CMD2"'"
set reboot "'"$CMD3"'"
set cmd [string trim $cmd /{/}]


switch -re $cmd {
	[f|F]2 {set fn ""}	
	[f|F]8 {set fn ""}	
	[f|F]9 {set fn ""}	
	[f|F]12 {set fn ""}	
	default {set fn ""}
}

#should be able to connect within 10 seconds
set timeout 10
#StrictHostKeyChecking disables, well, key checking
spawn ssh -o StrictHostKeyChecking=no $user@$ip
expect {
"*yes/no" { send "yes\r"; exp_continue }
"*assword:" { send "$password\r" }
#exit return value 1 for timeout
timeout { puts "connection timeout, pls check network!";exit 1 }
}
expect {
-re {#|>} {
#rebooting system, comment it if you want to reboot manually
send $reboot 
#here is how magic works
send "start -script /HOST/console\r"
}
timeout { puts "wrong password!";exit 2 }
}
#assuming the boot process take less than 10 minutes
set timeout $reboot_time
#and here
expect {
#send Fn when prompted
-re {F8} {
#a little more try doesnt hurt
send $fn
send $fn
send $fn
send "("
send "("
send "("
}
timeout {exit 3}
}
#chaning back and quit
set timeout 10
expect {
-re {#|>} {
send "exit\r"
}
timeout { exit }
}
expect eof
'  > /dev/null
case "$?" in
	1) echo -e "\033[31m Network Error \033[0m";;
	2) echo -e "\033[31m Wrong Password \033[0m";;
	3) echo -e "\033[31m Menu didn't came up before timeout, make sure system is rebooted and change timeout with -t! \033[0m";;
	*) echo -e "\033[33m Pls sit back and enjoy a cup of coffee while the dummy did your job! \033[0m";;
esac
