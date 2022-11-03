#!/bin/bash
sudo apt update && apt upgrade
groupadd prometheus
useradd -s /sbin/nologin --system -g prometheus prometheus
mkdir /var/lib/prometheus

for i in rules rules.d files_sd; 
    do sudo mkdir -p /etc/prometheus/${i}; 
done

apt install curl
mkdir -p /tmp/prometheus

cd /tmp/prometheus
curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep browser_download_url | grep linux-amd64 | cut -d '"' -f 4 | wget -qi –
tar xvf prometheus*.tar.gz
cd /tmp/prometheus/prometheus-2.38.0.linux-amd64

mv prometheus promtool /usr/local/bin/

# Setting up Prometheus configuration file "Prometheus.yml"
cat <<EOF | sudo tee /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']
EOF

sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml
mv consoles/ console_libraries/ /etc/prometheus/

# Creating the Prometheus Systemd service.
cat <<EOF | sudo tee /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target
[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries
[Install]
WantedBy=multi-user.target
EOF

for i in rules rules.d files_sd; 
    do sudo chown -R prometheus:prometheus /etc/prometheus/${i}; 
done

for i in rules rules.d files_sd; 
    do sudo chmod -R 775 /etc/prometheus/${i}; 
done

chown -R prometheus:prometheus /var/lib/prometheus/

systemctl daemon-reload
systemctl start/enable prometheus