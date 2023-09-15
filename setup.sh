#!/bin/bash
# Set the PATH to include common command directories
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

ulimit -n 65536 # increase reaf file limit
ufw disable # disable Firewall

# Define the range of ports
FIRST_PORT=1000
LAST_PORT=2000
# Set username and password
USERNAME="onet"
PASSWORD="onet"

# Get IP addresses
IP4=$(curl -4 -s icanhazip.com)
IP6_PREFIX=$(curl -6 -s icanhazip.com | cut -d':' -f1-3)
# Extract the last part of IPv4
IP4_LAST_PART=$(echo "$IP4" | awk -F. '{print $4}')

# Calculate STATIC64 using the combination of Current_date and last part of IPv4
CURRENT_DATE=$(date +"%Y%m%d")
STATIC64=$(( (CURRENT_DATE + IP4_LAST_PART + 100) % 65536 ))
STATIC64=$(printf "%04x" "$STATIC64")
echo "Static 64: ${STATIC64}"

INTERFACE="eth0"
# Generate hashed password
HASHED_PASSWORD=$(openssl passwd -apr1 "$PASSWORD")

# Generate squid.passwords file with hashed password
echo "$USERNAME:$HASHED_PASSWORD" > /etc/squid/squid.passwords



echo "Removing old configs"
rm -rf "/etc/squid/acls/outgoing.conf"
rm -rf "/etc/squid/acls/ports.conf"

# Display IP information
echo "Internal ip = ${IP4}. Prefix for ip6 = ${IP6_PREFIX}"
echo "Using /64: ${IP6_PREFIX}:${STATIC64}"
# Define an array of characters for generating IPv6 addresses
array=(1 2 3 4 5 6 7 8 9 0 a b c d e f)

# Define a function to generate an IPv6 address with random segments
gen64() {
    ip64() {
        echo "${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}"
    }
    echo "$1:${STATIC64}:$(ip64):$(ip64):$(ip64):$(ip64)"
}

# Generate random ipv6
gen_ipv6() {
    seq $FIRST_PORT $LAST_PORT | while read port; do
        echo "$(gen64 $IP6_PREFIX)"
    done
}

# Generate ports configuration and save to file
generate_ports_config() {
    for port in $(seq $FIRST_PORT $LAST_PORT); do
        echo "http_port ${IP4}:${port}"
    done
}

# Generate ACLs and save to outgoing.conf
generate_acls() {
    for port in $(seq $FIRST_PORT $LAST_PORT); do
        port_var="port$port"
        echo "acl ${port_var} localport ${port}"
    done
}

# Generate tcp_outgoing_address lines and append to outgoing.conf
generate_tcp_outgoing() {
    for port in $(seq $FIRST_PORT $LAST_PORT); do
        port_var="port$port"
        ip=$(echo "$IPv6_ADDRESSES" | head -n 1)
        IPv6_ADDRESSES=$(echo "$IPv6_ADDRESSES" | sed -e '1d')
        echo "tcp_outgoing_address ${ip} ${port_var}"
    done
}

generate_interfaces() {
    # Clear old interfaces
    for iface in $(ip -o -6 addr show | awk '{print $2}'); do
        # Iterate through all IPv6 addresses on the current network interface
        ip -6 addr show dev $iface | awk '/inet6/ && !/:$/ {print $2}' | while read addr; do
            # Check if the address is a full IPv6 address (not a subnet)
            if [[ "$addr" == *:*:*:*:*:*:*:* ]]; then
                # Delete the full IPv6 address
                ip -6 addr del $addr dev $iface
                #echo "Deleted $addr on $iface"
            fi
        done
    done
    # Restart Network
    systemctl restart networking
    sleep 3
    # Read IPv6 addresses from file
    IPv6_ADDRESSES=$(cat /etc/squid/ipv6add.acl)

    # Add each IPv6 address to the interface
    for ip in $IPv6_ADDRESSES; do
        ip -6 addr add $ip/64 dev $INTERFACE
    done    
}

gen_ipv6 >/etc/squid/ipv6add.acl

generate_ports_config > /etc/squid/acls/ports.conf

# Read IPv6 addresses from file
IPv6_ADDRESSES=$(cat /etc/squid/ipv6add.acl)

# Generate ACLs and tcp_outgoing_address lines, and save to outgoing.conf
generate_acls > /etc/squid/acls/outgoing.conf
generate_tcp_outgoing >> /etc/squid/acls/outgoing.conf

generate_interfaces

# Restart Squid service
systemctl restart squid

# Set up crontab job to run the entire script every 15 minutes
# Check if the cron job already exists before adding it
if ! crontab -l | grep -q "/root/setup.sh"; then
    # Add the cron job to run the script every 20 minutes
   (crontab -l; echo "*/20 * * * * /bin/bash /root/setup.sh >> /root/cron.log 2>&1") | crontab -
    echo "Added cron job to run the script every 20 minutes."
else
    echo "Cron job already exists."
fi

echo "Finished"

# set shutdown_lifetime to 2 to reduce rotate time
