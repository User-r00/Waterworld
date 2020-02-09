#!/usr/bin/env bash

# Setup a Digital Ocean droplet

# Get sudo password for future commands.
sudo su

# Get username to be setup.
echo "Enter a username. This will be used to create a new user."
echo ">: "
read USERNAME

# Clear iptables
echo "Clearing iptables."
iptables -F >> commands.log

# Block null packets - ddos protection
echo "Blocking null packets."
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP >> commands.log

# Syn-flood block
echo "Blocking syn-flood."
iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP >> commands.log

# Inherent deny all
echo "Setting up inherent deny all."
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP >> commands.log

# Allow localhost on all ports
echo "Setting up localhost on all ports."
iptables -A INPUT -i lo -j ACCEPT >> commands.log

# Allow ssh
echo "Opening SSH port."
iptables -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT >> commands.log

# Install iptables-persisten to enable firewall at server boot
echo "Installing iptables-persistent."
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
sudo apt-get install -qy iptables-persistent >> commands.log


# Ensure that the iptable rules are saved
echo "Restarting ufw."
service ufw restart >> commands.log

# List iptables.
echo "Saving iptables to commands.log."
echo "" >> commands.log
echo "" >> commands.log
echo "IPTABLES" >> commands.log
iptables -L >> commands.log
# iptables -L

# Add a new user for ssh so that we aren’t using root
echo "Creating $USERNAME user account."
sudo adduser $USERNAME >> commands.log

# Make user sudo user
echo "Setting $USERNAME user account to be a sudoer."
usermod -aG sudo $USERNAME >> commands.log

# Edit sshd_config
cd /etc/ssh/  >> commands.log
sudo vi sshd_config  >> commands.log
# Add or uncomment the line ‘PermitRootLogin no’
# If there is a line that says ‘PermitRootLogin yes’ just change it.

# Restart the ssh service
echo "Restarting SSH service."
service ssh restart >> commands.log

# Install fail2ban
echo "Installing fail2ban."
sudo apt-get install fail2ban >> commands.log

# Fail2ban help page
# fail2ban-client -h
# If this shows up, fail2ban installed and setup properly

# Config fail2ban
# Make sure ‘DAEMON’ line exists
# sudo vi /etc/init.d/fail2ban # No longer needed. Replaced by lines below.
echo 'Verifying fail2ban init.d.'
if grep -Fxq 'DAEMON=' /etc/init.d/fail2ban
then
    echo '/etc/init.d/fail2ban is configured correctly.'
else
    echo '[ERROR] Unable to manually configure /etc/init.d/fail2ban.'
fi

echo "Doing something with fail2ban. No clue. "
Fail2ban-client -d  >> commands.log

#Verify that Fail2ban sshd params are set correctly.
# echo 'Verifying fail2ban sshd backoffs.'
# Fail2ban-client -d | grep "['add', 'sshd', 'auto']" &> /dev/null
# if [ $? == 0 ]; then
#    echo "sshd set to auto."
# fi

# Fail2ban-client -d | grep "['set', 'sshd', 'bantime', 600]" &> /dev/null
# if [ $? == 0 ]; then
#    echo "sshd bantime set to 600."
# fi

# Fail2ban-client -d | grep "['set', 'sshd', 'maxretry', 5]" &> /dev/null
# if [ $? == 0 ]; then
#    echo "sshd maxretry set to 5."
# fi

# Set fail2ban params
Fail2ban-client set sshd bantime 600 >> commands.log
Fail2ban-client set sshd maxretry 5 >> commands.log

# Start fail2ban
service fail2ban start >> commands.log

# Install pip3
sudo apt-get install python3-pip >> commands.log

# Reboot the server. 