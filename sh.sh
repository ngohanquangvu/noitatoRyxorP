#!/bin/bash
#####################################################################
#######            Initialize Script                        #########
#####################################################################
apt install git
git clone https://github.com/khacnam/dev.git
cd dev
chmod 0755 addips.sh
chmod 0755 Configure
chmod 0755 Menu
chmod 0755 Rotation
sh Configure
