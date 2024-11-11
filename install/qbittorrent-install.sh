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
msg_ok "Installed Dependencies"

echo "vpn token: $VPN_TOKEN"

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
