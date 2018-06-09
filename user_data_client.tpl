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

# gives some lead time to the server to make sure it is started before connecting to it
sleep 20

# run client processes and store pids in array
pids=()
for i in {1..${num_procs}}; do
  { time jwt-cracker-client -h ${server_ip} ; } >> /var/log/messages 2>&1 &
  pids[$${i}]=$!
done

echo "Started clients with PID: $${pids[*]}" >> /var/log/messages

# wait for all pids
for pid in $${pids[*]}; do
  wait $pid
done

echo "client jobs completed - shutdown in 10 seconds"
sleep 10
aws ec2 terminate-instances --region eu-west-1 --instance-ids $(curl -s http://169.254.169.254/latest/meta-data/instance-id)
