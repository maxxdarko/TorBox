#!/bin/bash

# This file is a part of TorBox, an easy to use anonymizing router based on Raspberry Pi.
# Copyright (C) 2020 Patrick Truffer
# Contact: anonym@torbox.ch
# Website: https://www.torbox.ch
# Github:  https://github.com/radio24/TorBox
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it is useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
# DESCRIPTION
# This script installs the newest version of TorBox on a clean, running
# Raspbian lite.
#
# SYNTAX
# ./run_install.sh
#
# IMPORTANT
# Start it as normal user (usually as pi)!
# Dont run it as root (no sudo)!
#
##########################################################

# Table of contents for this script:
# 1. Checking for internet connection
# 2. Updating the system
# 3. Adding the Tor repository to the source list.
# 4. Installing all necessary packages
# 5. Configuring Tor and obfs4proxy
# 6. Downloading and installing the latest version of TorBox
# 7. Installing all configuration files
# 8. Disabling Bluetooth
# 9. hanging the password of pi to "CHANGE-IT"
#10. Configure the system services and rebooting

##########################################################

##### SET VARIABLES ######
#
# SIZE OF THE MENU
#
# How many items do you have in the main menu?
NO_ITEMS=9
#
# How many lines are only for decoration and spaces?
NO_SPACER=0
#
#Set the the variables for the menu
MENU_WIDTH=80
MENU_WIDTH_REDUX=60
MENU_HEIGHT_25=25
MENU_HEIGHT_15=15
MENU_HEIGHT=$((8+NO_ITEMS+NO_SPACER))
MENU_LIST_HEIGHT=$((NO_ITEMS+$NO_SPACER))

#Colors
RED='\033[1;31m'
WHITE='\033[1;37m'
NOCOLOR='\033[0m'

#Other variables


# 1. Checking for internet connection
# Currently a working internet connection is mandatory. Probably in a later
# version, we will include an option to install the TorBox from a compressed
# file.

clear
echo -e "${RED}[+] Step 1: Do we have internet?${NOCOLOR}"
wget -q --spider http://google.com
if [ $? -eq 0 ]; then
  echo -e "${RED}[+] Yes, we have! :-)${NOCOLOR}"
else
  echo -e "${RED}[+] Hmmm, no we don't have... :-(${NOCOLOR}"
  echo -e "${RED}[+] We will check again in about 30 seconds...${NOCOLOR}"
  sleeo 30
  echo -e "${RED}[+] Trying again...${NOCOLOR}"
  wget -q --spider https://google.com
  if [ $? -eq 0 ]; then
    echo -e "${RED}[+] Yes, now, we have an internet connection! :-)${NOCOLOR}"
  else
    echo -e "${RED}[+] Hmmm, still no internet connection... :-(${NOCOLOR}"
    echo -e "${RED}[+] We will try to catch a dynamic IP adress and check again in about 30 seconds...${NOCOLOR}"
    sudo dhclient -r
    sleep 5
    sudo dhclient &>/dev/null &
    sleep 30
    echo -e "${RED}[+] Trying again...${NOCOLOR}"
    wget -q --spider https://google.com
    if [ $? -eq 0 ]; then
      echo -e "${RED}[+] Yes, now, we have an internet connection! :-)${NOCOLOR}"
    else
      echo -e "${RED}[+] Hmmm, still no internet connection... :-(${NOCOLOR}"
      echo -e "${RED}[+] We will add a Google nameserver (8.8.8.8) to /etc/resolv.conf and try again...${NOCOLOR}"
      sudo cp /etc/resolv.conf /etc/resolv.conf.bak
      sudo printf "\n# Added by TorBox install script\nnameserver 8.8.8.8\n" | sudo tee -a /etc/resolv.conf
      sleep 15
      echo -e "${RED}[+] Dumdidum...${NOCOLOR}"
      sleep 15
      echo -e "${RED}[+] Trying again...${NOCOLOR}"
      wget -q --spider https://google.com
      if [ $? -eq 0 ]; then
        echo -e "${RED}[+] Yes, now, we have an internet connection! :-)${NOCOLOR}"
      else
        echo -e "${RED}[+] Hmmm, still no internet connection... :-(${NOCOLOR}"
        echo -e "${RED}[+] Internet connection is mandatory. We cannot continue - giving up!${NOCOLOR}"
        exit 1
      fi
    fi
  fi
fi

# 2. Updating the system
sleep 5
clear
echo -e "${RED}[+] Step 2: Updating the system and installing additional software...${NOCOLOR}"
sudo apt-get -y update
sudo apt-get -y dist-upgrade
sudo apt-get -y clean
sudo apt-get -y autoclean
sudo apt-get -y autoremove

# 3. Adding the Tor repository to the source list.
sleep 10
clear
echo -e "${RED}[+] Step 3: Adding the Tor repository to the source list....${NOCOLOR}"
echo ""
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
sudo printf "\n# Added by TorBox update script\ndeb https://deb.torproject.org/torproject.org buster main\ndeb-src https://deb.torproject.org/torproject.org buster main\n" | sudo tee -a /etc/apt/sources.list
sudo curl https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | sudo apt-key add -
sudo apt-get update

# 4. Installing all necessary packages
sleep 10
clear
echo -e "${RED}[+] Step 4: Installing all necessary packages....${NOCOLOR}"
sudo apt-get -y install hostapd isc-dhcp-server obfs4proxy usbmuxd wicd-curses dnsmasq dnsutils tcpdump iftop vnstat links2 debian-goodies apt-transport-https dirmngr python3-setuptools ntpdate screen nyx
sudo apt-get -y install tor deb.torproject.org-keyring

# 5. Configuring Tor and obfs4proxy
sleep 10
clear
echo -e "${RED}[+] Step 5: Configuring Tor and obfs4proxy....${NOCOLOR}"
sudo setcap 'cap_net_bind_service=+ep' /usr/bin/obfs4proxy
sudo sed -i "s/^NoNewPrivileges=yes/NoNewPrivileges=no/g" /lib/systemd/system/tor@default.service
sudo sed -i "s/^NoNewPrivileges=yes/NoNewPrivileges=no/g" /lib/systemd/system/tor@.service

# 6. Downloading and installing the latest version of TorBox
echo -e "${RED}[+] Step 6.: Download and install the latest version of TorBox....${NOCOLOR}"
cd
wget -L https://github.com/radio24/TorBox/archive/master.zip
unzip master.zip
rm -r torbox
mv TorBox-master torbox
rm -r master.zip

# 7. Installing all configuration files
sleep 10
cd
cd torbox
echo -e "${RED}[+] Step 7: Installing all configuration files....${NOCOLOR}"
sudo cp /etc/default/hostapd /etc/default/hostapd.bak
sudo cp etc/default/hostapd /etc/default/
echo -e "${RED}[+] Copied /etc/default/hostapd -- backup done${NOCOLOR}"
sudo cp /etc/default/isc-dhcp-server /etc/default/isc-dhcp-server.bak
sudo cp etc/default/isc-dhcp-server /etc/default/
echo -e "${RED}[+] Copied /etc/default/isc-dhcp-server -- backup done${NOCOLOR}"
sudo cp /etc/dhcp/dhclient.conf /etc/dhcp/dhclient.conf.bak
sudo cp etc/dhcp/dhclient.conf /etc/dhcp/
echo -e "${RED}[+] Copied /etc/dhcp/dhclient.conf -- backup done${NOCOLOR}"
sudo cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhpcd.conf.bak
sudo cp etc/dhcp/dhcpd.conf /etc/dhcp/
echo -e "${RED}[+] Copied /etc/dhcp/dhcpd.conf -- backup done${NOCOLOR}"
sudo cp /etc/hostapd/hostapd.conf /etc/hostapd/hostapd.conf.bak
sudo cp etc/hostapd/hostapd.conf /etc/hostapd/
echo -e "${RED}[+] Copied /etc/iptables.ipv4.nat -- backup not necessary${NOCOLOR}"
sudo cp etc/iptables.ipv4.nat /etc/
echo -e "${RED}[+] Copied /etc/hosts -- backup done${NOCOLOR}"
sudo cp /etc/motd /etc/motd.bak
sudo cp etc/motd /etc/
echo -e "${RED}[+] Copied /etc/motd -- backup not necessary${NOCOLOR}"
sudo cp etc/network/interfaces /etc/network/
echo -e "${RED}[+] Copied /etc/network/interfaces -- backup done${NOCOLOR}"
sudo cp /etc/rc.local /etc/rc.local.bak
sudo cp etc/rc.local /etc/
echo -e "${RED}[+] Copied /etc/rc.local -- backup done${NOCOLOR}"
if grep "#net.ipv4.ip_forward=1" /etc/sysctl.conf ; then
  sudo cp /etc/sysctl.conf /etc/sysctl.conf.bak
  sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
  echo -e "${RED}[+] Changed /etc/sysctl.conf -- backup done${NOCOLOR}"
fi
sudo cp /etc/tor/torrc /etc/tor/torrc.bak
sudo cp etc/tor/torrc /etc/tor/
echo -e "${RED}[+] Copied /etc/tor/torrc -- backup done${NOCOLOR}"
sudo cp /etc/wicd/manager-settings.conf /etc/wicd/manager-settings.conf.bak
sudo cp etc/wicd/manager-settings.conf /etc/wicd/
echo -e "${RED}[+] Copied /etc/wicd/manager-settings.conf -- backup done${NOCOLOR}"
sudo cp /etc/wicd/wired-settings.conf /etc/wicd/wired-settings.conf.bak
sudo cp etc/wicd/wired-settings.conf /etc/wicd/
echo -e "${RED}[+] Copied /etc/wicd/wired-settings.conf -- backup done${NOCOLOR}"
echo -e "${RED}[+] Activating IP forwarding${NOCOLOR}"
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
echo -e "${RED}[+] Changing .profile${NOCOLOR}"
cd
sudo cp .profile .profile.bak
sudo printf "\n# Added by TorBox\ncd torbox\nsleep 2\n./menu\n" | sudo tee -a .profile

# 8. Disabling Bluetooth
sleep 10
clear
echo -e "${RED}[+] Step 8: Because of security considerations, we completely disable the Bluetooth functionality${NOCOLOR}"
sudo printf "\n# Added by TorBox\ndtoverlay=disable-bt\n." | sudo tee -a /boot/config.txt
sudo systemctl disable hciuart.service
sudo systemctl disable bluealsa.service
sudo systemctl disable bluetooth.service
sudo apt-get -y purge bluez
sudo apt-get -y autoremove

# We have to disable that or ask the user for a password
# 9. Changing the password of pi to "CHANGE-IT"
sleep 10
clear
echo -e "${RED}[+] Step 9: We change the password of the user \"pi\" to \"CHANGE-IT\".${NOCOLOR}"
echo 'pi:CHANGE-IT' | sudo chpasswd

# 10. Configure the system services and rebooting
echo ""
echo -e "${RED}[+] Step 10: Configure the system services...${NOCOLOR}"
sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo systemctl start hostapd
sudo systemctl unmask isc-dhcp-server
sudo systemctl enable isc-dhcp-server
sudo systemctl start isc-dhcp-server
sudo systemctl unmask tor
sudo systemctl enable tor
sudo systemctl start tor
sudo systemctl unmask ssh
sudo systemctl enable ssh
sudo systemctl start ssh
sudo systemctl stop dnsmasq
sudo systemctl disable dnsmasq
sudo systemctl daemon-reload
echo ""
echo -e "${RED}[+] Stop logging, now..${NOCOLOR}"
sudo service rsyslog stop
sudo systemctl disable rsyslog
echo -e "${RED}[+] Copied /etc/hostapd/hostapd.conf -- backup done${NOCOLOR}"
cd torbox
sudo cp /etc/hostname /etc/hostname.bak
sudo cp etc/hostname /etc/
echo -e "${RED}[+] Copied /etc/hostname -- backup done${NOCOLOR}"
sudo cp /etc/hosts /etc/hosts.bak
sudo cp etc/hosts /etc/

echo""
read -p "The system needs to reboot. This will also erase all log files. Would you do it now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  clear
  echo -e "${RED}[+] Erasing ALL LOG-files...${NOCOLOR}"
  echo " "
  for logs in `sudo find /var/log -type f`; do
    echo -e "${RED}[+]${NOCOLOR} Erasing $logs"
    sudo rm $logs
    sleep 1
  done
  echo -e "${RED}[+]${NOCOLOR} Erasing .bash_history"
  sudo rm ../.bash_history
  sudo history -c
  echo ""
  echo echo -e "${RED}[+] Rebooting...${NOCOLOR}"
  sudo reboot
else
  echo ""
  echo -e "${White}[+] You need to reboot the system as soon as possible!${NOCOLOR}"
  echo -e "${White}[+] The log files are not deleted, yet. You can do this later with configuration sub-menu.${NOCOLOR}"
fi
exit 0
