#!/usr/bin/env bash
#
# Summary: clean up / harden system before creating an image
#

cmdExists() {
    if command -v "$1" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}
getDisto() {
    cat /etc/os-release 2>/dev/null | grep '^ID=' | cut -d '=' -f 2 | cut -d '"' -f 2
}
joinwith() {
    local START="$1" IFS="$2" END="$3" ARR=()
    shift;shift;shift

    for VAR in "$@"; do
        ARR+=("${START}${VAR}${END}")
    done

    echo "${ARR[*]}"
}

# make sure all security updates are installed
# remove insecure services (FTP, Telnet, Rlogin/Rsh)
if cmdExists 'apt-get'; then
    # grub updates adhere to ucf not debconf
    # make sure ucf defaults to unattended upgrade
    unset UCF_FORCE_CONFFOLD
    export UCF_FORCE_CONFFNEW=YES
    ucf --purge /boot/grub/menu.lst

    apt-get -y update
    apt-get -y upgrade

    apt-get -y --purge remove xinetd nis yp-tools tftpd atftpd tftpd-hpa telnetd rsh-server rsh-redone-server

    apt-get -y autoremove
    apt-get -y autoclean

elif cmdExists 'yum'; then
    yum -y update
    yum -y upgrade

    yum -y erase xinetd ypserv tftp-server telnet-server rsh-server

    yum -y autoremove
    yum -y clean all
fi

# harden sshd server configs
(cat <<'EOF'
# |== SSHD Server Settings ==|
Port 22
Protocol 2

# |== Log Settings ==|
SyslogFacility AUTH
LogLevel INFO

# |== Authentication Settings ==|
# we only allow pubkey auth using ssh protocol v2
PermitRootLogin no
StrictModes yes
# enable protocol v2 auth
PubkeyAuthentication yes
# disable protocol v1 auth
RSAAuthentication no
ChallengeResponseAuthentication no
PasswordAuthentication no
KerberosAuthentication no
GSSAPIAuthentication no
PermitEmptyPasswords no
# HostKeys for protocol v2
# see: man sshd_config for more details
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_dsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# |== Security Settings ==|
# Process is unprivileged until auth is complete
UsePrivilegeSeparation yes
# Make brute force attempts much harder
# NOTE: if you have many identity keys (>5) each one causes an auth attempt and this may cause auth failure
# clients with this issue need to specify the key explicitly for that host (on cmdline or in ~/.ssh/ssh_config)
# ex) ssh -o IdentitiesOnly=yes -i ~/.ssh/<your key>.pem <user>@<host>
MaxAuthTries 5
LoginGraceTime 60
# Don't read the user's ~/.rhosts and ~/.shosts files
IgnoreRhosts yes
# Don't allow remote host auth protocol v1
RhostsRSAAuthentication no
# Don't allow remote host auth protocol v2
HostbasedAuthentication no
# PAM is needed for some 2-factor auth solutions
UsePAM yes
# Some exploits have been published using X11 offsets
# so we disable it just in case
X11Forwarding no

# |== General sSettings ==|
PrintMotd yes
TCPKeepAlive yes
ClientAliveInterval 240
# Allow client to pass locale environment variable
AcceptEnv LANG LC_*
# Allow sftp over ssh
Subsystem sftp /usr/lib/openssh/sftp-server
EOF
) > /etc/ssh/sshd_config

# delete any accounts attempting to be root
BAD_USERS=$(joinwith '' ';' 'd' `awk -F ':' '($3 == "0") && !/root/ {print FNR}' /etc/passwd`)
sed -i "/${BAD_USERS}/d" /etc/passwd

# kernel hardening
# source: https://www.cyberciti.biz/tips/linux-security.html
(cat <<'EOF'
######################################################################
# /etc/sysctl.conf - Configuration file for setting system variables
# See /etc/sysctl.d/ for additional system variables.
# See sysctl.conf (5) for information.
######################################################################

# Turn on execshield
kernel.exec-shield=1
kernel.randomize_va_space=1
# Enable IP spoofing protection
net.ipv4.conf.all.rp_filter=1
# Disable IP source routing
net.ipv4.conf.all.accept_source_route=0
# Ignoring broadcasts request
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.icmp_ignore_bogus_error_messages=1
# Make sure spoofed packets get logged
net.ipv4.conf.all.log_martians = 1
EOF
) > /etc/sysctl.conf

# remove logs and any information from build process
rm -rf /tmp/* /var/tmp/*
history -c
cat /dev/null | tee /root/.*history /home/*/.*history
unset HISTFILE
find /var/log -mtime -1 -type f -exec truncate -s 0 {} \;
rm -rf /var/log/*.gz /var/log/*.[0-9] /var/log/*-????????
rm -rf /var/lib/cloud/instances/*
rm -f /root/.ssh/authorized_keys /etc/ssh/*key* /home/*/.ssh/authorized_keys
touch /etc/ssh/revoked_keys; chmod 600 /etc/ssh/revoked_keys
dd if=/dev/zero of=/zerofile 2> /dev/null; sync; rm -f /zerofile; sync
cat /dev/null > /var/log/lastlog; cat /dev/null > /var/log/wtmp

# ensure address space layout randomization (ASLR) is enabled
echo '2' > /proc/sys/kernel/randomize_va_space

# regenerate host server host keys
if cmdExists 'apt-get'; then
    dpkg-reconfigure -f noninteractive openssh-server
fi
systemctl restart sshd

exit 0
