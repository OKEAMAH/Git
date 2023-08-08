#!/bin/bash

# Force re-apply

# Parameters

# Docker deployment script
##########################

cat > /tmp/start.sh <<EOF
apt update
apt install libgmp-dev curl libev-dev libhidapi-dev python3 openssh-server -y
mkdir -p /root/.ssh
mkdir -p /run/sshd

/usr/sbin/sshd -D -p 30000 -e
EOF

docker_registry_url="europe-west1-docker.pkg.dev/nl-dal/docker-registry"

docker_image_name="debian-tezos"

docker run -p 30000-30999:30000-30999 --name tezos $docker_registry_url/$docker_image_name:latest
