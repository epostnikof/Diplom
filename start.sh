#!/usr/bin/env bash

#Check ROOT
if  [ "$(id -u)" != 0 ]
then
    echo root permission required >&2
    exit 1
fi

function loopChannels() {
    ##function switches channels of the wireless network
    echo "Available network interfaces:"
    iwconfig
    read -p "Enter name WLAN interface: " wlan
    iwconfig $wlan mode monitor
    echo "Monitor mode is enabled"
    echo "Channel change started"
    while [[ true ]]; do
        #statements
        for channels in {1..13}
        do
            sleep 2
            iwconfig $wlan channel $channels
        done
    done
}
function onlyMonitor() {
    echo "Available network interfaces:"
    iwconfig
    read -p "Enter name WLAN interface: " wlan
    iwconfig $wlan mode monitor
    echo "Monitor mode is enabled"
    echo ""
    echo "Check:"
    echo ""
    iwconfig
    exit 0
}

function connectWifi() {
    echo "Plese, connect to Wi-fi"
    nmcli radio wifi on
    nmcli dev wifi list
    read -p "Enter SSID: " SSID
    nmcli --ask dev wifi connect $SSID
}

function onlyManaged() {
    echo "Available network interfaces:"
    iwconfig
    read -p "Enter name WLAN interface: " wlan
    iwconfig $wlan mode managed
    echo "Managed mode is enabled"
    echo ""
    echo "Check:"
    echo ""
    iwconfig
    exit 0
}


function manageMenu() {
    echo "Welcome to script!"
    echo ""
    echo "What do you want to do?"
    echo "   1) Enable Monitor mode and run change channel"
    echo "   2) Only enable Monitor mode"
    echo "   3) Connect to Wi-Fi"
    echo "   4) Reinstall the required software"
    echo "	 5) Enable Managed mode back"
    echo "   6) Exit"
    until [[ $MENU_OPTION =~ ^[1-6]$ ]]; do
        read -rp "Select an option [1-6]: " MENU_OPTION
    done

    case $MENU_OPTION in
        1)
            loopChannels
        ;;
        2)      onlyMonitor
        ;;
        3)
            connectWifi
        ;;
        4)
            configOS
        ;;
        5)      onlyManaged
        ;;
        6)
            exit 0
        ;;
    esac
}

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

function configOS() {
    ##Setting OS
    ##Install packeges and other
    checkOS
    if  [ $OS = "ubuntu" ] || [ $OS = "debian" ]; then
        add-apt-repository ppa:wireshark-dev/stable -y
        apt update
        apt install wireshark tshark network-manager net-tools wireless-tools -y
        usermod -aG wireshark "$(whoami)"
    fi

    if [ $OS = "fedora" ] || [ $OS = "centos" ]; then
        dnf install network-manager wireshark-qt tshark network-manager net-tools wireless-tools-y
        usermod -aG wireshark "$(whoami)"
    fi
}

##Check Programs
checkOS
if  [ $OS = "ubuntu" ] || [ $OS = "debian" ]; then
    #Check tshark
    if  [ "$(dpkg -l | grep tshark | awk '{print $2}')" != tshark ]
    then
        configOS
        manageMenu
    else
        manageMenu
    fi
fi

checkOS
if  [ $OS = "fedora" ] || [ $OS = "centos" ]; then
    #Check tshark
    if  [ "$(rpm -q wireshark)" = 0 ]
    then
        configOS
    else
        manageMenu
    fi
fi

###If configOS
#echo "Do you need Monitor mode?(y or n)"
#read answer
#if [ $answer == 'y' ] || [ $answer == 'yes' ]; then
#loopChannels ## to analyze traffic, you need to change channels
#fi


#if [ $answer == 'n' ] || [ $answer == 'no' ]; then
#connectWifi
#fi
