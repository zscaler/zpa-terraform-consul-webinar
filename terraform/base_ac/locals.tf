################################################################################
# A. Create the user_data file with necessary bootstrap variables for App
#    Connector registration. Used if variable use_zscaler_ami is set to false.
################################################################################
locals {
  al2userdata = <<AL2USERDATA
#!/usr/bin/bash
sleep 15
touch /etc/yum.repos.d/zscaler.repo
cat > /etc/yum.repos.d/zscaler.repo <<-EOT
[zscaler]
name=Zscaler Private Access Repository
baseurl=https://yum.private.zscaler.com/yum/el7
enabled=1
gpgcheck=1
gpgkey=https://yum.private.zscaler.com/gpg
EOT

sleep 60
#Install App Connector packages
yum install zpa-connector -y
#Stop the App Connector service which was auto-started at boot time
systemctl stop zpa-connector
#Create a file from the App Connector provisioning key created in the ZPA Admin Portal
#Make sure that the provisioning key is between double quotes
echo "${module.zpa_provisioning_key.provisioning_key}" > /opt/zscaler/var/provision_key
chmod 644 /opt/zscaler/var/provision_key
#Run a yum update to apply the latest patches
yum update -y
#Start the App Connector service to enroll it in the ZPA cloud
systemctl start zpa-connector
#Wait for the App Connector to download latest build
sleep 60
#Stop and then start the App Connector for the latest build
systemctl stop zpa-connector
systemctl start zpa-connector
AL2USERDATA
}

########################################################
# B. Create the user_data file with necessary bootstrap
    # variables for Consul Server
########################################################
locals {
  consulserveruserdata = <<CONSULSERVERUSERDATA
#!/bin/bash

# Wait for network
sleep 10

# Disable interactive apt prompts
export DEBIAN_FRONTEND=noninteractive

#######################################################################################
######################## SETUP ENVIRONMENT ############################################
#######################################################################################

HOME_DIR=ubuntu
# VAULTVERSION=1.13.1
VAULTDOWNLOAD=https://releases.hashicorp.com/vault/1.13.1/vault_1.13.1_linux_amd64.zip
VAULTCONFIGDIR=/etc/vault.d
VAULTDIR=/opt/vault

# CONSULVERSION=1.15.1
CONSULDOWNLOAD=https://releases.hashicorp.com/consul/1.15.1/consul_1.15.1_linux_amd64.zip
CONSULCONFIGDIR=/etc/consul.d
CONSULDIR=/opt/consul

# CTSVERSION=1.15.1
CTSDOWNLOAD=https://releases.hashicorp.com/consul-terraform-sync/0.7.0/consul-terraform-sync_0.7.0_linux_amd64.zip
CTSCONFIGDIR=/etc/consul-nia.d/consul-nia.env

sudo apt-get install -y software-properties-common
sudo apt-get update
sudo apt-get install -y unzip tree redis-tools jq curl tmux
sudo apt-get clean

# Disable the firewall
sudo ufw disable || echo "ufw not installed"

# Get IP and Region from metadata service
IP_ADDRESS="$(curl --silent http://169.254.169.254/latest/meta-data/local-ipv4)"
REGION="$(curl --silent http://169.254.169.254/latest/meta-data/placement/region)"

#######################################################################################
######################## INSTALL CONFIGURE CONSUL #####################################
#######################################################################################
# Download Consul
curl -L $CONSULDOWNLOAD > consul.zip

## Install Consul
sudo unzip consul.zip -d /usr/local/bin
sudo chmod 0755 /usr/local/bin/consul
sudo chown root:root /usr/local/bin/consul

## Configure Consul
sudo mkdir -p $CONSULCONFIGDIR
sudo chmod 755 $CONSULCONFIGDIR
sudo mkdir -p $CONSULDIR
sudo chmod 755 $CONSULDIR

# Consul
cat << EOF > /etc/consul.d/consul.hcl
server = true
ui = true
data_dir = "/opt/consul/data"
bind_addr = "0.0.0.0"
client_addr = "0.0.0.0"
advertise_addr = "$IP_ADDRESS"

bootstrap_expect = 1
log_level = "INFO"
retry_join = ["provider=aws tag_key=Env tag_value=consul"]

service {
    name = "consul"
}

connect {
  enabled = true
}

ports {
  grpc = 8502
}
EOF

sudo cat << EOF > /etc/systemd/system/consul.service
[Unit]
Description=Consul Agent
Requires=network-online.target
After=network-online.target

[Service]
Restart=on-failure
Environment=CONSUL_ALLOW_PRIVILEGED_PORTS=true
ExecStart=/usr/local/bin/consul agent -config-dir="/etc/consul.d"
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGTERM
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

#Enable Consul service
sudo systemctl enable consul.service
sudo systemctl start consul.service

#######################################################################################
######################## INSTALL CONFIGURE VAULT ######################################
#######################################################################################
# Download Vault
curl -L $VAULTDOWNLOAD > vault.zip

## Install Vault
sudo unzip vault.zip -d /usr/local/bin
sudo chmod 0755 /usr/local/bin/vault
sudo chown root:root /usr/local/bin/vault

## Configure
sudo mkdir -p $VAULTCONFIGDIR
sudo chmod 755 $VAULTCONFIGDIR
sudo mkdir -p $VAULTDIR
sudo chmod 755 $VAULTDIR

# Get IP from metadata service
IP_ADDRESS="$(curl --silent http://169.254.169.254/latest/meta-data/local-ipv4)"
REGION="$(curl --silent http://169.254.169.254/latest/meta-data/placement/region)"

# Vault
cat << EOF > /etc/vault.d/vault.hcl
ui = true
backend "consul" {
  path          = "vault/"
  address       = "$IP_ADDRESS:8500"
  cluster_addr  = "https://$IP_ADDRESS:8201"
  redirect_addr = "http://$IP_ADDRESS:8200"
}

listener "tcp" {
  address         = "0.0.0.0:8200"
  cluster_address = "$IP_ADDRESS:8201"
  tls_disable     = 1
}

seal "awskms" {
    region = "$REGION"
    kms_key_id = "${aws_kms_key.vault_kms_key.key_id}"
}

api_addr = "http://$IP_ADDRESS:8200"
cluster_addr = "http://$IP_ADDRESS:8201"
cluster_name = "vault-prod-$REGION"
ui = true
log_level = "INFO"
EOF

#Create Vault Systemd Config
sudo cat << EOF > /etc/systemd/system/vault.service
[Unit]
Description=Vault Agent
Requires=network-online.target
After=network-online.target

[Service]
Restart=on-failure
Environment=GOMAXPROCS=nproc
ExecStart=/usr/local/bin/vault server -config="/etc/vault.d/vault.hcl"
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGTERM
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable vault.service
sudo systemctl start vault.service

# Initialize Vault
HOME_DIR=ubuntu
IP_ADDRESS="$(curl --silent http://169.254.169.254/latest/meta-data/local-ipv4)"
export VAULT_ADDR=http://$IP_ADDRESS:8200
VAULT_ADDR=http://$IP_ADDRESS:8200 vault operator init -n 1 -t 1 &> /home/$HOME_DIR/vault_tokens.log
IP_ADDRESS="$(curl --silent http://169.254.169.254/latest/meta-data/local-ipv4)"
export VAULT_ADDR=http://$IP_ADDRESS:8200
vault operator init &> /home/$HOME_DIR/vault_tokens.log
vault status &> /home/$HOME_DIR/vault_status.log

echo "export CONSUL_RPC_ADDR=$IP_ADDRESS:8400" | sudo tee --append /home/$HOME_DIR/.bashrc
echo "export CONSUL_HTTP_ADDR=$IP_ADDRESS:8500" | sudo tee --append /home/$HOME_DIR/.bashrc
echo "export VAULT_ADDR=http://$IP_ADDRESS:8200" | sudo tee --append /home/$HOME_DIR/.bashrc

CONSULSERVERUSERDATA
}

########################################################
# C. Create the user_data file with necessary bootstrap
    # variables for Web Servers
########################################################
locals {
  webserveruserdata = <<WEBSERVERUSERDATA
#!/bin/bash

# Wait for network
sleep 10

# Disable interactive apt prompts
export DEBIAN_FRONTEND=noninteractive

HOME_DIR=ubuntu

# CONSULVERSION=1.15.1
CONSULDOWNLOAD=https://releases.hashicorp.com/consul/1.15.1/consul_1.15.1_linux_amd64.zip
CONSULCONFIGDIR=/etc/consul.d
CONSULDIR=/opt/consul

sudo apt-get install -y software-properties-common
sudo apt-get update
sudo apt-get install -y unzip tree redis-tools jq curl tmux
sudo apt-get clean

# Disable the firewall
sudo ufw disable || echo "ufw not installed"

# Get IP and Region from metadata service
IP_ADDRESS="$(curl --silent http://169.254.169.254/latest/meta-data/local-ipv4)"
REGION="$(curl --silent http://169.254.169.254/latest/meta-data/placement/region)"
HOSTNAME="$(curl --silent http://169.254.169.254/latest/meta-data/local-hostname)"

# Download Consul
curl -L $CONSULDOWNLOAD > consul.zip

## Install Consul
sudo unzip consul.zip -d /usr/local/bin
sudo chmod 0755 /usr/local/bin/consul
sudo chown root:root /usr/local/bin/consul

## Configure Consul
sudo mkdir -p $CONSULCONFIGDIR
sudo chmod 755 $CONSULCONFIGDIR
sudo mkdir -p $CONSULDIR
sudo chmod 755 $CONSULDIR

cat << EOF > /etc/consul.d/client.hcl
ui = true
log_level = "INFO"
data_dir = "/opt/consul/data"
bind_addr = "0.0.0.0"
client_addr = "0.0.0.0"
advertise_addr = "$IP_ADDRESS"
retry_join = ["provider=aws tag_key=Env tag_value=consul"]

connect {
  enabled = true
}

ports {
  grpc = 8502
}
EOF

#Create Systemd Config
sudo cat << EOF > /etc/systemd/system/consul.service
[Unit]
Description=Consul Agent
Requires=network-online.target
After=network-online.target

[Service]
Restart=on-failure
Environment=CONSUL_ALLOW_PRIVILEGED_PORTS=true
ExecStart=/usr/local/bin/consul agent -config-dir="/etc/consul.d"
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGTERM
User=root
Group=root

[Install]
WantedBy=multi-user.target

EOF

cat << EOF > /etc/consul.d/nginx.json
{
  "service": {
    "name": "web",
    "port": 80,
    "checks": [
      {
        "id": "web",
        "name": "web TCP Check",
        "tcp": "localhost:80",
        "interval": "10s",
        "timeout": "1s"
      }
    ]
  }
}
EOF

#Enable the service
sudo systemctl enable consul
sudo service consul start
sudo service consul status

#Install Dockers
sudo snap install docker
sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

#Run  nginx
sleep 10
cat << EOF > docker-compose.yml
version: "3.7"
services:
  web:
    image: nginxdemos/hello
    ports:
    - "80:80"
    restart: always
    command: [nginx-debug, '-g', 'daemon off;']
    network_mode: "host"
EOF
sudo docker-compose up -d

sudo hostnamectl set-hostname "$HOSTNAME"
sudo reboot
sudo systemctl enable consul
sudo service consul start
sudo service consul status

WEBSERVERUSERDATA
}
