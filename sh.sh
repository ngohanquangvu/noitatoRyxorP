wget https://raw.githubusercontent.com/khacnam/dev/main//Configure
wget https://raw.githubusercontent.com/khacnam/dev/main/addips.sh
wget https://raw.githubusercontent.com/khacnam/dev/main/Menu
wget https://raw.githubusercontent.com/khacnam/dev/main/rc.local
chmod 0777 Configure
chmod 0777 addips.sh
chmod 0777 Menu
rm -rf /etc/rc.local
mv /root/rc.local /etc/
cd /etc/
chmod 0755 /etc/rc.local
