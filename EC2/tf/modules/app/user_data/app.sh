#!/bin/bash -xe

# Start cfn-init
yum install -y aws-cfn-bootstrap awscli
/opt/aws/bin/cfn-init -v --region ${var.region} --stack ${AWS::StackName} --resource EC2ServerLaunchConfiguration || error_exit 'Failed to run cfn-init'

# Start app
docker run -d -p 80:3000 ikerry/node-app:latest

echo;
echo '### Wait until instance is registered as healthy in the ELB'
until [ "$state" == "InService" ]; do
  state=$(aws --region ${AWS::Region} elb describe-instance-health \
              --load-balancer-name ${ElasticLoadBalancer} \
              --instances $(curl -s http://169.254.169.254/latest/meta-data/instance-id) \
              --query InstanceStates[0].State \
              --output text)
  sleep 10
done

# signal success
/opt/aws/bin/cfn-signal -e $? --region ${AWS::Region} --stack ${AWS::StackName} --resource EC2ASG
