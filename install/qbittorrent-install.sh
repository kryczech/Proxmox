#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y nfs-common
$STD apt-get install -y gnupg gnupg1 gnupg2
mkdir -p /media/movies
mkdir -p /media/television
chmod -R 755 /media
echo "192.168.1.10:/volume1/Movies /media/movies nfs defaults 0 0" >> /etc/fstab
echo "192.168.1.10:/volume1/Television /media/television nfs defaults 0 0" >> /etc/fstab
systemctl deamon-reload
mount -a
msg_ok "Installed Dependencies"

read -p "Enter NordVPN token: " VPN_TOKEN
echo "vpn token: $VPN_TOKEN"

msg_info "Installing NordVPN"
$STD wget -qnc https://repo.nordvpn.com/gpg/nordvpn_public.asc -O- | apt-key add -
$STD echo "deb https://repo.nordvpn.com/deb/nordvpn/debian stable main" > /etc/apt/sources.list.d/nordvpn.list
$STD apt-get update
$STD apt-get install -y nordvpn
nordvpn login --token $VPN_TOKEN
nordvpn set lan-discovery on
nordvpn set autoconnect on
nordvpn set killswitch on
nordvpn connect
msg_ok "Installed NordVPN"

msg_info "Installing qbittorrent-nox"
$STD apt-get install -y qbittorrent-nox
mkdir -p /.config/qBittorrent/
cat <<EOF >/.config/qBittorrent/qBittorrent.conf
[BitTorrent]
Session\Interface=nordlynx
Session\InterfaceName=nordlynx

[Preferences]
WebUI\Port=8090
WebUI\UseUPnP=false
WebUI\Username=admin
EOF
msg_ok "qbittorrent-nox"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/qbittorrent-nox.service
[Unit]
Description=qBittorrent client
After=network.target
[Service]
ExecStart=/usr/bin/qbittorrent-nox --webui-port=8090
Restart=always
[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now qbittorrent-nox
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
