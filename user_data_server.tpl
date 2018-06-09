#!/usr/bin/env bash

# Set hostname
sudo hostname "${hostname}"
echo "127.0.0.1 ${hostname}" | sudo tee --append /etc/hosts
echo "${hostname}" | sudo tee /etc/hostname
sudo network restart
sudo service awslogs restart

# Enable SSH access
sudo mkdir -p /home/ubuntu/.ssh
sudo chown -R ubuntu:ubuntu /home/ubuntu/.ssh
sudo chmod -R 700 /home/ubuntu/.ssh
sudo echo "${ssh_key}" | sudo tee --append /home/ubuntu/.ssh/authorized_keys

# Start server in the background
{ time jwt-cracker-server -a ${alphabet} ${token} ; } >> /var/log/messages 2>&1 &
SERVER=$!

wait $SERVER

echo "Server job completed (${hostname}) - shutdown in 10 seconds" >> /var/log/messages
sleep 10
aws ec2 terminate-instances --region eu-west-1 --instance-ids $(curl -s http://169.254.169.254/latest/meta-data/instance-id)
