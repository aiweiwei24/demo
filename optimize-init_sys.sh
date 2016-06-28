#!/bin/bash
#################################################
#    File Name: optimize-init_sys.sh
#       Author: Energy
#         Mail: 2722982316@qq.com
#     Function: system optimize scripts
# Created Time: Sat 29 Aug 2015 12:06:12 PM CST
#################################################
#optimization linux system 
. /etc/init.d/functions

#change system directory: create seripts/software directory
function change_dir(){
	ShellDir="/server/scripts"
	SoftwareDir="/server/tools"
	mkdir -p $ShellDir &&\
	mkdir -p $SoftwareDir
}

#change system hostname
function change_hostname(){
    HostName="$1"
    hostname $HostName &&\
    sed -i -e "2s/=.*$/=$HostName/g" /etc/sysconfig/network &&\
    chk_hosts=$(grep -o "\b$HostName\b" /etc/hosts)
    get_ip=$(ifconfig eth0|awk -F "[ :]+" 'NR==2 {print $4}')
    if [ -z $chk_hosts ]
    then
        echo "$get_ip   $HostName" >>/etc/hosts
    else
        continue
    fi
}

#boot system optimize: setup chkconfig
function change_chkconfig(){
    Boot_options="$1"
    for boots in `chkconfig --list|grep "3:on"|awk '{print $1}'|grep -vE "$Boot_options"`
    do 
        chkconfig $boots off
    done
}

#setup system optimize: setup ulimit
function change_ulimit(){
	grep "*       -       nofile       65535" /etc/security/limits.conf >/dev/null 2>&1
	if [ $? -ne 0 ]
	then
		echo '*       -       nofile       65535' >>/etc/security/limits.conf 
	fi	
}

#setup system optimize: setup sysctl 
function change_sysctl(){
	cat /tmp/sysctl.conf >/etc/sysctl.conf &&\
	modprobe bridge &>/dev/null &&\
	sysctl -p >>/dev/null
}

#sshd software optimize: change sshd_conf
function change_sshdfile(){
    SSH_Port="port 22"
    SSH_ListenAddress=$(ifconfig eth0|awk -F "[ :]+" 'NR==2 {print $4}')
    SSH_PermitRootLogin="PermitRootLogin no"
    SSH_PermitEmptyPassword="PermitEmptyPasswords no"
    SSH_GSSAPI="GSSAPIAuthentication no"
    SSH_DNS="useDNS no"
	#sed -i -e "13s/.*/$SSH_Port/g" /etc/ssh/sshd_config
	sed -i -e "15s/.*/ListenAddress $SSH_ListenAddress/g" /etc/ssh/sshd_config
	#sed -i -e "42s/.*/$SSH_PermitRootLogin/g" /etc/ssh/sshd_config
	#sed -i -e "65s/.*/$SSH_PermitEmptyPassword/g" /etc/ssh/sshd_config
	sed -i -e "81s/.*/$SSH_GSSAPI/g" /etc/ssh/sshd_config
	sed -i -e "122s/.*/$SSH_DNS/g" /etc/ssh/sshd_config
}
      
#selinux software optimize: change disable
function change_selinux(){
    sed -i 's#SELINUX=.*#SELINUX=disabled#g' /etc/selinux/config &&\
    setenforce 0
}

#firewall software optimize: change stop
function change_firewall(){
    /etc/init.d/iptables stop >/dev/null 2>&1   
}

#crond software optimize: time synchronization
function change_update(){
	grep -i "#crond-id-001" /var/spool/cron/root >/dev/null 2>&1
	if [ $? -ne 0 ]
	then 
		echo '#crond-id-001:time sync by hq' >>/var/spool/cron/root
		echo "*/5 * * * * /usr/sbin/ntpdate time.nist.gov >/dev/null 2>&1">>/var/spool/cron/root
	fi
}

function main(){
    change_dir
    change_hostname "lvs-lb-01"
    change_chkconfig "crond|network|rsyslog|sshd|sysstat"
    change_ulimit
    change_sysctl
    change_sshdfile
    change_selinux
    change_firewall
    change_update
}
main
action "system optimize complete" /bin/true
