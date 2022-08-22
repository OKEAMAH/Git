
.PHONY: run-instance

MIME_ARCHIVE_FILES=cloud-config.yml compile-sources.sh
MIME_ARCHIVE=cloud-init-boot


$(MIME_ARCHIVE): $(MIME_ARCHIVE_FILES)
	cloud-init devel make-mime -a cloud-config.yml:cloud-config -a compile-sources.sh:x-shellscript-per-instance > $@

run-instance: $(MIME_ARCHIVE)
	./spawn-ec2.sh $<

#List all instances with tag Name:snoop-benchmark
.PHONY: describe-instances
describe-instances:
	aws ec2 describe-instances\
	 --filters "Name=tag:Name,Values=snoop-benchmark"\
	 --query "Reservations[*].Instances[*].{Instance:InstanceId,AZ:Placement.AvailabilityZone,IP:PublicIpAddress,LaunchTime:LaunchTime,TagName:Tags[?Key=='Name']|[0].Value,State:State.Name}"\
	 --output=table


