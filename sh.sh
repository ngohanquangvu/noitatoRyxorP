wget https://it4.vn/Configure
wget https://it4.vn/addips.sh
wget https://it4.vn/Menu
wget https://it4.vn/rc.local
chmod 0777 Configure
chmod 0777 addips.sh
chmod 0777 Menu
rm -rf /etc/rc.local
mv /root/rc.local /etc/
cd /etc/
chmod 0755 /etc/rc.local
