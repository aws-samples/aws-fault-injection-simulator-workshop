aws ec2 describe-instances \
--query "Reservations[*].Instances[*].{ID:InstanceId,AZ:Placement.AvailabilityZone,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}"  \
--filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='FisStackAsg/ASG'"  \
--output table