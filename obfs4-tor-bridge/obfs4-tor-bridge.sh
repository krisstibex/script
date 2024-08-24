#!/bin/bash

apt update
apt install tor obfs4proxy -y
sudo bash -c 'echo -e "Log notice file /var/log/tor/notices.log\nRunAsDaemon 1\nORPort auto\nExitpolicy reject *:*\nBridgeRelay 1\nServerTransportPlugin obfs4 exec /usr/bin/obfs4proxy\nServerTransportListenAddr obfs4 [::]:8081\nExtORPort auto\nPublishServerDescriptor 0\nNickname ohmytor\nRelayBandwidthRate 50 MB\nRelayBandwidthBurst 200 MB" > /etc/tor/torrc'
systemctl restart tor

FINGERPRINT=$(sudo cat /var/lib/tor/fingerprint | awk '{print $2}')
IP_ADDRESS=$(curl -4 -s ip.sb)
PORT=$(grep -Po '(?<=ServerTransportListenAddr obfs4 \[::\]:)\d+' /etc/tor/torrc)
BRIDGE_LINE=$(sudo cat /var/lib/tor/pt_state/obfs4_bridgeline.txt | grep '^Bridge obfs4' | sed -e 's/^Bridge //' -e "s/<IP ADDRESS>/${IP_ADDRESS}/" -e "s/<PORT>/${PORT}/" -e "s/<FINGERPRINT>/${FINGERPRINT}/")

echo "Your obfs4 bridge configuration:"
echo
echo -e "\033[1m$BRIDGE_LINE\033[0m"
echo
echo "Copy and use this line for your Tor configuration."
