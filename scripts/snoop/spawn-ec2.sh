#!/bin/bash

# Minimal script to spawn aws machine with snoop.
#
#set -u
ARGC=$#

if [ $ARGC -ne 1 ]; then
    printf "Usage: ./run_benchmark.sh cloud-config.yml <instance_type>"
    exit 1
fi

EC2_INIT_SCRIPT=$1
# INSTANCE_TYPE={$2:=c6i.8xlarge}
#INSTANCE_TYPE="c5.metal"
INSTANCE_TYPE=c6i.8xlarge	# This is much cheaper for just running the benchmark.

AWS_REGION=us-east-1
AMI="ami-052efd3df9dad4825"
#REGION US-EAST-1
# Ubuntu 22 (64-bit (x86)) = ami-052efd3df9dad4825
#REGION EU-WEST-3
# Ubuntu 22 (64-bit (x86)) = ami-011eaee8f509eadb7
#US-EAST-1 ubuntu 22.04 amd64


AWS_TAG_SPEC="ResourceType=instance,Tags=[{Key=Name,Value=snoop-benchmark}]"

JSON=$(aws ec2 run-instances\
 --image-id "$AMI"\
 --instance-type "$INSTANCE_TYPE"\
 --security-group-ids sg-03be6d508e0f3c1ad\
 --tag-specifications "$AWS_TAG_SPEC"\
 --iam-instance-profile Name="snoop-s3-access-profile"\
 --instance-initiated-shutdown-behavior terminate\
 --block-device-mapping "[ { \"DeviceName\": \"/dev/sda1\", \"Ebs\": { \"VolumeSize\": 60 } } ]"\
 --user-data file://"$EC2_INIT_SCRIPT"\
 )

## describe-instances requires a space-separated list of quoted strings
#echo $JSON | jq
echo "Writing instance json to run-instance_result.json"
echo $JSON > run-instance_result.json
AWS_EC2_INSTANCE_ID=$(echo "$JSON" | jq -r '.Instances|map(.InstanceId)|join(" ")')
## Get public ips of instances (in case we need to ssh)
IPS=$(aws ec2 describe-instances --instance-ids ${AWS_EC2_INSTANCE_ID} --query 'Reservations[*].Instances[*].PublicIpAddress')

echo "$IPS"
# Wait for ec2 instance reservation
echo "Waiting for ec2 instance ${AWS_EC2_INSTANCE_ID}"
aws ec2 wait instance-running --instance-ids ${AWS_EC2_INSTANCE_ID}



IPS=$(aws ec2 describe-instances --instance-ids ${AWS_EC2_INSTANCE_ID} --query 'Reservations[*].Instances[*].PublicIpAddress')
IP=$(echo $IPS | jq --raw-output '.[][0]')
echo "Waiting for cloud-init ${AWS_EC2_INSTANCE_ID} with ${IP} to complete"

CMD="ssh -oConnectTimeout=2 snoop@${IP} cloud-init status --wait --long"
CONT=255
#0 = remote command success
#1 = ssh command failed | cloud-init status failed
while test $CONT -gt 1
do
    sleep 1
    echo "Running: [$CMD]"
    $CMD
    CONT=$?

done
printf "benchmark machine ready: aws id: ${AWS_EC2_INSTANCE_ID}\nlogin with ssh snoop@${IP} and run ./tezos/tezos-snoop"