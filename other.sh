#!/bin/bash

# standard bash error handling
set -o errexit;
set -o pipefail;
set -o nounset;
# debug commands
# set -x;

function main() {
	install_bluetooth
}

function install_bluetooth() {
		echo '----------Installing Bluetooth----------'
  sudo apt install bluez-tools
}

onexit() {
     echo "GL HF"
}
trap onexit EXIT

main