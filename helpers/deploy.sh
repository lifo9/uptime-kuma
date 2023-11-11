#!/bin/bash
set -eu

bw config server $BW_SERVER
bw login --apikey

source .envrc >/dev/null 2>&1
ansible-playbook site.yml -i inventory.yml
