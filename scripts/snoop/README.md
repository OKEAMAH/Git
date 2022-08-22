Requirements

- Access to AWS through `aws` commandline
- `cloud-init`
##  cloud-init
### Debian/Ubuntu
```
apt-get install cloud-init
```
### OS X:
```
 pip3 install  --require-hashes  -r<(echo 'https://github.com/canonical/cloud-init/archive/refs/tags/22.3.tar.gz --hash=sha256:d3c5d129e88678b3db56472a4dddc4612aa09f1c367e4f3048477f16dc0b711a')
 ```


## Files
- **cloud.config.yml** cloud-init + initial boot script.
- **spawn-ec2.sh** script to
-

## Getting started

Add your public-ssh key to `cloud-init.yaml:users.ssh_authorized_keys`
```
make run-instance
```
## Cleanup
Always to clean up your instance(s)
```
make describe-instances
aws ec2 terminate-instances --instance-ids <instance-id+>
```

## List of potential improvemnets

 -  [ ] Run benchmark with a specific configuration
 -  [ ] Upload result to s3.


