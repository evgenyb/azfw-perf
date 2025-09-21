#!/bin/sh

sudo add-apt-repository universe
sudo apt update

echo "Installing iperf3..." 
sudo apt install -y iperf3
iperf3 -s &
