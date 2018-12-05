#!/bin/bash -euo

echo "Checking that agent is running"
until $(curl --output /dev/null --silent --head --fail curl -s http://169.254.169.254/latest/meta-data/instance-id); do
  printf '.'
  sleep 1
done
printf "\nDone\n"

yum update -y aws-cfn-bootstrap awslogs awscli
REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}')
INSTANCEID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# aws logs configs
mkdir -p /etc/awslogs/

AWSCLICONF="/etc/awslogs/awscli.conf"
touch $AWSCLICONF && chmod 644 $AWSCLICONF
cat >> $AWSCLICONF << EOF
[default]
region = $REGION
[plugins]
cwlogs = cwlogs
EOF

AWSLOGSCONF="/etc/awslogs/awslogs.conf"
touch $AWSLOGSCONF && chmod 644 $AWSLOGSCONF
cat >> $AWSLOGSCONF << EOF
[general]
state_file = /var/lib/awslogs/agent-state
[/var/log/messages]
datetime_format = %b %d %H:%M:%S
file = /var/log/messages
buffer_duration = 5000
log_stream_name = $INSTANCEID/var/log/messages
initial_position = start_of_file
log_group_name = ${log_group_name}
[/var/log/secure]
datetime_format = %b %d %H:%M:%S
file = /var/log/secure
log_stream_name = $INSTANCEID/var/log/secure
log_group_name = ${log_group_name}
initial_position = start_of_file
EOF

# signal success
/opt/aws/bin/cfn-signal -e $exit_code --region $REGION --stack $CFN_STACK --resource ASG
