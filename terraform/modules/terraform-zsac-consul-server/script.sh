#!/bin/bash

sleep 60s;

HOME_DIR=ubuntu
IP_ADDRESS="$(curl --silent http://169.254.169.254/latest/meta-data/local-ipv4)"
export VAULT_ADDR=http://$IP_ADDRESS:8200
VAULT_ADDR=http://$IP_ADDRESS:8200 vault operator init -n 1 -t 1 > /home/$HOME_DIR/vault_tokens.log
IP_ADDRESS="$(curl --silent http://169.254.169.254/latest/meta-data/local-ipv4)"
export VAULT_ADDR=http://$IP_ADDRESS:8200
vault operator init > /home/$HOME_DIR/vault_tokens.log
vault status > /home/$HOME_DIR/vault_status.log

echo "export CONSUL_RPC_ADDR=$IP_ADDRESS:8400" | sudo tee --append /home/$HOME_DIR/.bashrc
echo "export CONSUL_HTTP_ADDR=$IP_ADDRESS:8500" | sudo tee --append /home/$HOME_DIR/.bashrc
echo "export VAULT_ADDR=http://$IP_ADDRESS:8200" | sudo tee --append /home/$HOME_DIR/.bashrc