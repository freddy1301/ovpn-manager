# ovpn-manager

Simple Bash script to Add/Remove/Export Client Certificates of your OpenVPN Docker Instance and also Install your OpenVPN Server (only on Debian Systems)

![image](https://github.com/freddy1301/ovpn-clientmanager/assets/97679739/360cf255-b45c-40a0-b2ba-241beb9fad4d)

✅ Easy to use

✅ Installs everything for you

✅ Keeps System clean

✅ Fancy looking ✨ ASCII Art ✨

✅ Removes leftover Configuration files

🔶 Does not handle errors very well :/

### What do I need?
1. Sudo and Docker Privileges on your system
2. Screen Installed

### How to Install
Just download the file straight from the main branch and run it on your OpenVPN Server.

It will work as a normal user with sudo privileges but wont be able to put your configurations into /opt/openvpn/clients

```
wget https://raw.githubusercontent.com/freddy1301/ovpn-manager/main/ovpn-manager.sh && chmod +x ovpn-manager.sh && sudo apt update && sudo apt install screen -y && ./ovpn-manager.sh
```
