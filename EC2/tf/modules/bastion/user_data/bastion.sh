#!/bin/bash -xe

yum update -y aws-cfn-bootstrap awscli
REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}')

# Start cfn-init
/opt/aws/bin/cfn-init -v --region $REGION --stack ${AWS::StackName} --resource BastionLaunchConfiguration || error_exit 'Failed to run cfn-init'

# signal success
/opt/aws/bin/cfn-signal -e 0 --region $REGION --stack ${AWS::StackName} --resource BastionASG


# REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}')
# INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
# aws ec2 associate-address --region $REGION --instance-id $INSTANCE_ID --allocation-id ${eip_id}
#
# cat <<"INSTANCES_SCRIPT" > /etc/update-motd.d/60-update-list-of-running-instances
# #!/bin/bash
# aws configure set region ${region}
# echo ""
# echo ""
# echo "Current instances grouped by AutoScaling Groups:"
# # get all ASG
# for asg in $(aws autoscaling describe-auto-scaling-groups --output text  --query 'AutoScalingGroups[?contains(AutoScalingGroupName, `${env}`) == `true`].AutoScalingGroupName'); do
# echo ""
# echo "Autoscaling group name: $asg"
# # get all instances in ASG
# for ip in $(aws ec2 describe-instances --filters Name=tag-key,Values='aws:autoscaling:groupName' Name=tag-value,Values=$asg --output text --query 'Reservations[*].Instances[*].[PrivateIpAddress]'); do
#   echo $ip
# done
# echo ""
# echo "========================================================================="
# done
# echo ""
# echo "Log on to the boxes with: ssh <IP address>"
# echo ""
# INSTANCES_SCRIPT
#
# chmod +x /etc/update-motd.d/60-update-list-of-running-instances
