#!/usr/bin/env bash

#CheckOS
function checkOS() {
	if [[ -e /etc/debian_version ]]; then
		OS="debian"
		source /etc/os-release

		if [[ $ID == "debian" || $ID == "raspbian" ]]; then
			if [[ $VERSION_ID -lt 9 ]]; then
				echo "Your version of Debian is not supported."
				echo ""
				echo "However, if you're using Debian >= 9 or unstable/testing then you can continue, at your own risk."
				echo ""
				until [[ $CONTINUE =~ (y|n) ]]; do
					read -rp "Continue? [y/n]: " -e CONTINUE
				done
				if [[ $CONTINUE == "n" ]]; then
					exit 1
				fi
			fi
		elif [[ $ID == "ubuntu" ]]; then
			OS="ubuntu"
			MAJOR_UBUNTU_VERSION=$(echo "$VERSION_ID" | cut -d '.' -f1)
			if [[ $MAJOR_UBUNTU_VERSION -lt 16 ]]; then
				echo "Your version of Ubuntu is not supported."
				echo ""
				echo "However, if you're using Ubuntu >= 16.04 or beta, then you can continue, at your own risk."
				echo ""
				until [[ $CONTINUE =~ (y|n) ]]; do
					read -rp "Continue? [y/n]: " -e CONTINUE
				done
				if [[ $CONTINUE == "n" ]]; then
					exit 1
				fi
			fi
		fi
	elif [[ -e /etc/system-release ]]; then
		source /etc/os-release
		if [[ $ID == "fedora" || $ID_LIKE == "fedora" ]]; then
			OS="fedora"
		fi
		if [[ $ID == "centos" || $ID == "rocky" || $ID == "almalinux" ]]; then
			OS="centos"
			if [[ ! $VERSION_ID =~ (7|8) ]]; then
				echo "Your version of CentOS is not supported."
				echo ""
				echo "The script only support CentOS 7 and CentOS 8."
				echo ""
				exit 1
			fi
		fi
		if [[ $ID == "ol" ]]; then
			OS="oracle"
			if [[ ! $OS = "oracle" ]]; then
				echo "Oracle Linux is not supported."
				echo ""
				exit 1
			fi
		fi
		if [[ $ID == "amzn" ]]; then
			OS="amzn"
      if [[ $VERSION_ID == "2" ]] || [[ $VERSION_ID != "2" ]]; then
				echo "Amazon Linux is not supported."
				echo ""
				exit 1
			fi
		fi
  elif [[ -e /etc/arch-release ]]; then
		OS=arch
    echo "Arch Linux is not supported"
    exit 1
	fi
}

function message_Stop() {
    #STOP message
    echo ""
    echo "Process started"
    echo "Press Ctrl + C to STOP"
    echo ""
}

function tshark_all() {
    #This function is useful when working in monitore mode
    echo "List interfaces: "
    echo "Please wait..."
    tshark -D
    read -p "Enter interface name: " IFname
    read -p "Enter the path to save the dump (default is '/home/$(whoami)): " path_d
  if [ -z $path_d ]
  then
    message_Stop
  	tshark -i $IFname -T ek > $HOME/"$(date +'%d.%m.%Y_%H.%M')".json
  else
    message_Stop
       	tshark -i $IFname -T ek > $path_d/"$(date +'%d.%m.%Y_%H.%M')".json
  fi
}

function tshark_filter_MAC() {
  #This function filters on MAC address
  message_Stop
  tshark -D
  read -p "Enter interface name: " IFname
  read -p "Enter MAC address: " MAC_addr
  read -p "Enter the path to save the dump (default is '/home/$(whoami)): " path_d
if [ -z $path_d ]
then
      message_Stop
      tshark -i $IFname -Y "wlan.bssid == $(echo $MAC_addr | tr "[A-Z]" "[a-z]")" -T ek > $HOME/"$(date +'%d.%m.%Y_%H.%M')".json
else
      message_Stop
      tshark -i $IFname -Y "wlan.bssid == $(echo $MAC_addr | tr "[A-Z]" "[a-z]")" -T ek > $path_d/"$(date +'%d.%m.%Y_%H.%M')".json
fi
}

function filter_Channel() {
  #Only traffic on a specific channel
      echo ""
      echo "Welcome!"
      echo "To analyze packets on a specific channel, enter a number between 1 and 13, where the number will be the channel number."
      echo ""
      echo "Please stop the 'start.sh' script if it is currently looping through the wireless channels, put the adapter into Monitor mode "
      echo ""
      echo "Available network interfaces: "
      tshark -D
      echo ""
      read -p "Enter Name Interface: " IFname
      read -p "Enter number channell : " num
      echo ""
if
	[ $num -lt 1 ] || [ $num -gt 13 ] ;
then
	echo "ERROR! Enter number between 1 and 13"
	echo "The script will run again..."
	sleep 3
	filter_Channel
fi
	read -p "Enter the path to save the dump (default is '/home/$(whoami)): " path_d
 if [ -z $path_d ]
 then
      message_Stop
      tshark -i $IFname -Y "wlan_radio.channel == $num" -T ek > $HOME/"$(date +'%d.%m.%Y_%H.%M')".json
 else
      message_Stop
      tshark -i $IFname -Y "wlan_radio.channel == $num" -T ek > $path_d/"$(date +'%d.%m.%Y_%H.%M')".json
fi
}

function startMenu() {
	echo "Welcome to the Wireless Traffic Analysis script"
	echo ""
	echo "This script helps you analyze wireless traffic.It should run second. "
	echo ""
	echo "What do you want to do?"
	echo "   1) Dump all networks (requires a lot of memory)"
	echo "   2) Dump by MAC Address"
	echo "   3) Dump all networks by channel"
	echo "   4) Dump by network packet type"
	echo "   5) Exit"
	until [[ $MENU_OPTION =~ ^[1-5]$ ]]; do
		read -rp "Select an option [1-5]: " MENU_OPTION
	done

	case $MENU_OPTION in
		1)
		tshark_all
		;;
		2)
		tshark_filter_MAC
		;;
		3)
		filter_Channel
		;;
		4)
		filter_TypePacketsMenu
		;;
		5)
		exit 0
		;;
	esac
}

function fctype0 () {
	#This function is useful when working in monitore mode
	echo "List interfaces: "
	echo "Please wait..."
	tshark -D
	read -p "Enter interface name: " IFname
	read -p "Enter the path to save the dump (default is '/home/$(whoami)): " path_d
	if [ -z $path_d ]
	then
		message_Stop
		tshark -i $IFname -Y "wlan.fc.type == 0" -T ek > $HOME/"$(date +'%d.%m.%Y_%H.%M')".json
	else
		message_Stop
		tshark -i $IFname -Y "wlan.fc.type == 0" -T ek > $path_d/"
		".json
	fi
}
function fcType1 () {
	#This function is useful when working in monitore mode
	echo "List interfaces: "
	echo "Please wait..."
	tshark -D
	read -p "Enter interface name: " IFname
	read -p "Enter the path to save the dump (default is '/home/$(whoami)): " path_d
if [ -z $path_d ]
then
	message_Stop
	tshark -i $IFname -Y "wlan.fc.type == 1" -T ek > $HOME/"
	".json
else
	message_Stop
			tshark -i $IFname  -Y "wlan.fc.type == 1" -T ek > $path_d/"$(date +'%d.%m.%Y_%H.%M')".json
fi
}
function fcType2 () {
	#This function is useful when working in monitore mode
	echo "List interfaces: "
	echo "Please wait..."
	tshark -D
	read -p "Enter interface name: " IFname
	read -p "Enter the path to save the dump (default is '/home/$(whoami)): " path_d
if [ -z $path_d ]
then
	message_Stop
	tshark -i $IFname -Y "wlan.fc.type == 2" -T ek > $HOME/"$(date +'%d.%m.%Y_%H.%M')".json

else
	message_Stop
			tshark -i $IFname -Y "wlan.fc.type == 2" -T ek > $path_d/"$(date +'%d.%m.%Y_%H.%M')".json
fi
}
function fcSubType0 () {
	#This function is useful when working in monitore mode
	echo "List interfaces: "
	echo "Please wait..."
	tshark -D
	read -p "Enter interface name: " IFname
	read -p "Enter the path to save the dump (default is '/home/$(whoami)): " path_d
if [ -z $path_d ]
then
	message_Stop
	tshark -i $IFname -Y "wlan.fc.type_subtype == 0x00" -T ek > $HOME/"$(date +'%d.%m.%Y_%H.%M')".json
else
	message_Stop
			tshark -i $IFname -Y "wlan.fc.type_subtype == 0x00" -T ek > $path_d/"$(date +'%d.%m.%Y_%H.%M')".json
fi
}
function fcSubType01 () {
	#This function is useful when working in monitore mode
	echo "List interfaces: "
	echo "Please wait..."
	tshark -D
	read -p "Enter interface name: " IFname
	read -p "Enter the path to save the dump (default is '/home/$(whoami)): " path_d
if [ -z $path_d ]
then
	message_Stop
	tshark -i $IFname -Y "wlan.fc.type_subtype == 0x01" -T ek > $HOME/"$(date +'%d.%m.%Y_%H.%M')".json
else
	message_Stop
			tshark -i $IFname -Y "wlan.fc.type_subtype == 0x01"  -T ek > $path_d/"$(date +'%d.%m.%Y_%H.%M')".json
fi
}
function fcSubtype02 () {
	#This function is useful when working in monitore mode
	echo "List interfaces: "
	echo "Please wait..."
	tshark -D
	read -p "Enter interface name: " IFname
	read -p "Enter the path to save the dump (default is '/home/$(whoami)): " path_d
if [ -z $path_d ]
then
	message_Stop
	tshark -i $IFname -Y "wlan.fc.type_subtype == 0x02" -T ek > $HOME/"$(date +'%d.%m.%Y_%H.%M')".json
else
	message_Stop
			tshark -i $IFname -Y "wlan.fc.type_subtype == 0x02" -T ek > $path_d/"$(date +'%d.%m.%Y_%H.%M')".json
fi
}
function fcSubtype03 () {
	#This function is useful when working in monitore mode
	echo "List interfaces: "
	echo "Please wait..."
	tshark -D
	read -p "Enter interface name: " IFname
	read -p "Enter the path to save the dump (default is '/home/$(whoami)): " path_d
if [ -z $path_d ]
then
	message_Stop
	tshark -i $IFname -Y "wlan.fc.type_subtype == 0x03" -T ek > $HOME/"$(date +'%d.%m.%Y_%H.%M')".json
else
	message_Stop
			tshark -i $IFname  -Y "wlan.fc.type_subtype == 0x03" -T ek > $path_d/"$(date +'%d.%m.%Y_%H.%M')".json
fi
}
function fcSubtype04 () {
	#This function is useful when working in monitore mode
	echo "List interfaces: "
	echo "Please wait..."
	tshark -D
	read -p "Enter interface name: " IFname
	read -p "Enter the path to save the dump (default is '/home/$(whoami)): " path_d
if [ -z $path_d ]
then
	message_Stop
	tshark -i $IFname -Y "wlan.fc.type_subtype == 0x04" -T ek > $HOME/"$(date +'%d.%m.%Y_%H.%M')".json
else
	message_Stop
			tshark -i $IFname -Y "wlan.fc.type_subtype == 0x04" -T ek > $path_d/"$(date +'%d.%m.%Y_%H.%M')".json
fi
}
function fcSubtype05 () {
	#This function is useful when working in monitore mode
	echo "List interfaces: "
	echo "Please wait..."
	tshark -D
	read -p "Enter interface name: " IFname
	read -p "Enter the path to save the dump (default is '/home/$(whoami)): " path_d
if [ -z $path_d ]
then
	message_Stop
	tshark -i $IFname -Y "wlan.fc.type_subtype == 0x05" -T ek > $HOME/"$(date +'%d.%m.%Y_%H.%M')".json
else
	message_Stop
			tshark -i $IFname -Y "wlan.fc.type_subtype == 0x05" -T ek > $path_d/"$(date +'%d.%m.%Y_%H.%M')".json
fi
}
function fcSubtype08 () {
	#This function is useful when working in monitore mode
	echo "List interfaces: "
	echo "Please wait..."
	tshark -D
	read -p "Enter interface name: " IFname
	read -p "Enter the path to save the dump (default is '/home/$(whoami)): " path_d
if [ -z $path_d ]
then
	message_Stop
	tshark -i $IFname -Y "wlan.fc.type_subtype == 0x08" -T ek > $HOME/"$(date +'%d.%m.%Y_%H.%M')".json
else
	message_Stop
			tshark -i $IFname -Y "wlan.fc.type_subtype == 0x08" -T ek > $path_d/"$(date +'%d.%m.%Y_%H.%M')".json
fi
}
function fcSubtype00A () {
	#This function is useful when working in monitore mode
	echo "List interfaces: "
	echo "Please wait..."
	tshark -D
	read -p "Enter interface name: " IFname
	read -p "Enter the path to save the dump (default is '/home/$(whoami)): " path_d
if [ -z $path_d ]
then
	message_Stop
	tshark -i $IFname -Y "wlan.fc.type_subtype == 0x0A" -T ek > $HOME/"$(date +'%d.%m.%Y_%H.%M')".json
else
	message_Stop
			tshark -i $IFname -Y "wlan.fc.type_subtype == 0x0A" -T ek > $path_d/"$(date +'%d.%m.%Y_%H.%M')".json
fi
}
function fcSubtype00B () {
	#This function is useful when working in monitore mode
	echo "List interfaces: "
	echo "Please wait..."
	tshark -D
	read -p "Enter interface name: " IFname
	read -p "Enter the path to save the dump (default is '/home/$(whoami)): " path_d
if [ -z $path_d ]
then
	message_Stop
	tshark -i $IFname -Y "wlan.fc.type_subtype == 0x0B" -T ek > $HOME/"$(date +'%d.%m.%Y_%H.%M')".json
else
	message_Stop
			tshark -i $IFname -Y "wlan.fc.type_subtype == 0x0B" -T ek > $path_d/"$(date +'%d.%m.%Y_%H.%M')".json
fi
}
function fcSubtype00C () {
	#This function is useful when working in monitore mode
	echo "List interfaces: "
	echo "Please wait..."
	tshark -D
	read -p "Enter interface name: " IFname
	read -p "Enter the path to save the dump (default is '/home/$(whoami)): " path_d
if [ -z $path_d ]
then
	message_Stop
	tshark -i $IFname -Y "wlan.fc.type_subtype == 0x0C" -T ek > $HOME/"$(date +'%d.%m.%Y_%H.%M')".json
else
	message_Stop
			tshark -i $IFname -Y "wlan.fc.type_subtype == 0x0C" -T ek > $path_d/"$(date +'%d.%m.%Y_%H.%M')".json
fi
}
function fcSubtype00D () {
	#This function is useful when working in monitore mode
	echo "List interfaces: "
	echo "Please wait..."
	tshark -D
	read -p "Enter interface name: " IFname
	read -p "Enter the path to save the dump (default is '/home/$(whoami)): " path_d
if [ -z $path_d ]
then
	message_Stop
	tshark -i $IFname -Y "wlan.fc.type_subtype == 0x0D" -T ek > $HOME/"$(date +'%d.%m.%Y_%H.%M')".json
else
	message_Stop
			tshark -i $IFname -Y "wlan.fc.type_subtype == 0x0D" -T ek > $path_d/"$(date +'%d.%m.%Y_%H.%M')".json
fi
}
function fcSubtype018 () {
	#This function is useful when working in monitore mode
	echo "List interfaces: "
	echo "Please wait..."
	tshark -D
	read -p "Enter interface name: " IFname
	read -p "Enter the path to save the dump (default is '/home/$(whoami)): " path_d
if [ -z $path_d ]
then
	message_Stop
	tshark -i $IFname -Y "wlan.fc.type_subtype == 0x18" -T ek > $HOME/"$(date +'%d.%m.%Y_%H.%M')".json
else
	message_Stop
			tshark -i $IFname -Y "wlan.fc.type_subtype == 0x18" -T ek > $path_d/"$(date +'%d.%m.%Y_%H.%M')".json
fi
}
function fcSubtype019 () {
	#This function is useful when working in monitore mode
	echo "List interfaces: "
	echo "Please wait..."
	tshark -D
	read -p "Enter interface name: " IFname
	read -p "Enter the path to save the dump (default is '/home/$(whoami)): " path_d
if [ -z $path_d ]
then
	message_Stop
	tshark -i $IFname -Y "wlan.fc.type_subtype == 0x19" -T ek > $HOME/"$(date +'%d.%m.%Y_%H.%M')".json
else
	message_Stop
			tshark -i $IFname -Y "wlan.fc.type_subtype == 0x19" -T ek > $path_d/"$(date +'%d.%m.%Y_%H.%M')".json
fi
}
function fcSubtype01A () {
	#This function is useful when working in monitore mode
	echo "List interfaces: "
	echo "Please wait..."
	tshark -D
	read -p "Enter interface name: " IFname
	read -p "Enter the path to save the dump (default is '/home/$(whoami)): " path_d
if [ -z $path_d ]
then
	message_Stop
	tshark -i $IFname -Y "wlan.fc.type_subtype == 0x1A" -T ek > $HOME/"$(date +'%d.%m.%Y_%H.%M')".json
else
	message_Stop
			tshark -i $IFname -Y "wlan.fc.type_subtype == 0x1A" -T ek > $path_d/"$(date +'%d.%m.%Y_%H.%M')".json
fi
}
function fcSubtype01B () {
	#This function is useful when working in monitore mode
	echo "List interfaces: "
	echo "Please wait..."
	tshark -D
	read -p "Enter interface name: " IFname
	read -p "Enter the path to save the dump (default is '/home/$(whoami)): " path_d
if [ -z $path_d ]
then
	message_Stop
	tshark -i $IFname -Y "wlan.fc.type_subtype == 0x1B" -T ek > $HOME/"$(date +'%d.%m.%Y_%H.%M')".json
else
	message_Stop
			tshark -i $IFname -Y "wlan.fc.type_subtype == 0x1B" -T ek > $path_d/"$(date +'%d.%m.%Y_%H.%M')".json
fi
}
function fcSubtype01C () {
	#This function is useful when working in monitore mode
	echo "List interfaces: "
	echo "Please wait..."
	tshark -D
	read -p "Enter interface name: " IFname
	read -p "Enter the path to save the dump (default is '/home/$(whoami)): " path_d
if [ -z $path_d ]
then
	message_Stop
	tshark -i $IFname -Y "wlan.fc.type_subtype == 0x1C" -T ek > $HOME/"$(date +'%d.%m.%Y_%H.%M')".json
else
	message_Stop
			tshark -i $IFname -Y "wlan.fc.type_subtype == 0x1C" -T ek > $path_d/"$(date +'%d.%m.%Y_%H.%M')".json
fi
}
function fcSubtype01D () {
	#This function is useful when working in monitore mode
	echo "List interfaces: "
	echo "Please wait..."
	tshark -D
	read -p "Enter interface name: " IFname
	read -p "Enter the path to save the dump (default is '/home/$(whoami)): " path_d
if [ -z $path_d ]
then
	message_Stop
	tshark -i $IFname -Y "wlan.fc.type_subtype == 0x1D" -T ek > $HOME/"$(date +'%d.%m.%Y_%H.%M')".json
else
	message_Stop
			tshark -i $IFname -Y "wlan.fc.type_subtype == 0x1D" -T ek > $path_d/"$(date +'%d.%m.%Y_%H.%M')".json
fi
}
function fcSubtype01E () {
	#This function is useful when working in monitore mode
	echo "List interfaces: "
	echo "Please wait..."
	tshark -D
	read -p "Enter interface name: " IFname
	read -p "Enter the path to save the dump (default is '/home/$(whoami)): " path_d
if [ -z $path_d ]
then
	message_Stop
	tshark -i $IFname -Y "wlan.fc.type_subtype == 0x1E" -T ek > $HOME/"$(date +'%d.%m.%Y_%H.%M')".json
else
	message_Stop
			tshark -i $IFname -Y "wlan.fc.type_subtype == 0x1E" -T ek > $path_d/"$(date +'%d.%m.%Y_%H.%M')".json
fi
}
function fcSubtype024 () {
	#This function is useful when working in monitore mode
	echo "List interfaces: "
	echo "Please wait..."
	tshark -D
	read -p "Enter interface name: " IFname
	read -p "Enter the path to save the dump (default is '/home/$(whoami)): " path_d
if [ -z $path_d ]
then
	message_Stop
	tshark -i $IFname -Y "wlan.fc.type_subtype == 0x24" -T ek > $HOME/"$(date +'%d.%m.%Y_%H.%M')".json
else
	message_Stop
			tshark -i $IFname -Y "wlan.fc.type_subtype == 0x24" -T ek > $path_d/"$(date +'%d.%m.%Y_%H.%M')".json
fi
}
function fcSubtype028 () {
	#This function is useful when working in monitore mode
	echo "List interfaces: "
	echo "Please wait..."
	tshark -D
	read -p "Enter interface name: " IFname
	read -p "Enter the path to save the dump (default is '/home/$(whoami)): " path_d
if [ -z $path_d ]
then
	message_Stop
	tshark -i $IFname -Y "wlan.fc.type_subtype == 0x24" -T ek > $HOME/"$(date +'%d.%m.%Y_%H.%M')".json
else
	message_Stop
			tshark -i $IFname -Y "wlan.fc.type_subtype == 0x24" -T ek > $path_d/"$(date +'%d.%m.%Y_%H.%M')".json
fi
}
function fcSubtype02C () {
	#This function is useful when working in monitore mode
	echo "List interfaces: "
	echo "Please wait..."
	tshark -D
	read -p "Enter interface name: " IFname
	read -p "Enter the path to save the dump (default is '/home/$(whoami)): " path_d
if [ -z $path_d ]
then
	message_Stop
	tshark -i $IFname -Y "wlan.fc.type_subtype == 0x2C" -T ek > $HOME/"$(date +'%d.%m.%Y_%H.%M')".json
else
	message_Stop
			tshark -i $IFname -Y "wlan.fc.type_subtype == 0x2C" -T ek > $path_d/"$(date +'%d.%m.%Y_%H.%M')".json
fi
}

function filter_TypePacketsMenu() {

	echo "Welcome to the Wireless Traffic Analysis script"
	echo ""
	echo "This script helps you analyze wireless traffic.It should run second. "
	echo ""
	echo "Select the type (subtype) of the wireless signal:"
	echo ""
	select numbers	in "Control frame (0)" "Control frame (1)" "Data frame (2)" "Communication request (0x00)" "Connection setup response (0x01)" "Reconnect Request (0x02)" "Reconnect response (0x03)" "Probing Request (0x04)" "Response to probing (0x05)" "Signal packet (0x08)" "Disconnect (0x0A)" "Authentication (0x0B)" "Authentication Denied (0x0C)" "Action frame (0x0D)" "Block confirmation requests (0x18)" "Lock confirmation (0x19)" "Energy saving poll (0x1A)" "Transfer Request (0x1B)" "Ready to receive (0x1C)" "Reception confirmation (0х1D)" "End of conflict-free period (0x1E)" "NULL data (0x24)" "Quality of Service Data (0x28)" "Empty quality of service data (0x2C)" "Exit"
	do
	case $numbers in
	"Control frame (0) " )	fctype0 ;;
	"Control frame (1)" ) 	fcType1 ;;
	"Data frame (2)" )	fcType2 ;;
	"Communication request (0x00)" )	fcSubType0 ;;
	"Connection setup response (0x01)" )	fcSubType01 ;;
	"Reconnect Request (0x02)" ) fcSubtype02 ;;
	"Reconnect response (0x03)")	fcSubtype03 ;;
	"Probing Request (0x04)")  fcSubtype04 ;;
	"Response to probing (0x05)")  fcSubtype05 ;;
	"Signal packet (0x08)")	fcSubtype08 ;;
	"Disconnect (0x0A)")	fcSubtype00A ;;
	"Authentication (0x0B)") fcSubtype00B ;;
	"Authentication Denied (0x0C)")	fcSubtype00C ;;
	"Action frame (0x0D)")	fcSubtype00D ;;
	"Block confirmation requests (0x18)")	fcSubtype018 ;;
	"Lock confirmation (0x19)")	fcSubtype019 ;;
	"Energy saving poll (0x1A)")	fcSubtype01A ;;
	"Transfer Request (0x1B)") fcSubtype01B ;;
	"Ready to receive (0x1C)") fcSubtype01C ;;
	"Reception confirmation (0х1D)")	fcSubtype01D ;;
	"End of conflict-free period (0x1E)")	fcSubtype01E ;;
	"NULL data (0x24)")	fcSubtype024 ;;
	"Quality of Service Data (0x28)")	fcSubtype028 ;;
	"Empty quality of service data (0x2C)")	fcSubtype02C ;;
	"Exit")	exit 0 ;;
		esac
	done
}


###END FUNCTIONS###

##Check Programs
checkOS
if  [ $OS = "ubuntu" ] || [ $OS = "debian" ]; then
#Check tshark
  if  [ "$(dpkg -l | grep tshark | awk '{print $2}')" != tshark ]
  then
      echo "First run start.sh"
      exit 1
  else
    startMenu
    echo 0
  fi
fi

checkOS
if  [ $OS = "fedora" ] || [ $OS = "centos" ]; then
#Check tshark
  if  [ "$(rpm -q wireshark)" = 0 ]
  then
    echo "First run start.sh"
    exit 1
  else
    echo 0
	startMenu
  fi
fi
