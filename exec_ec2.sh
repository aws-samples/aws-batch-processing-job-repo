#!/bin/bash

STACK_NAME=fargate-batch-job
REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
ACCOUNT_NUMBER=$(aws sts get-caller-identity --query 'Account' --output text)

SOURCE_REPOSITORY=$PWD
echo ' Creating CloudFormation Stack '
aws cloudformation create-stack --stack-name $STACK_NAME --parameters ParameterKey=StackName,ParameterValue=$STACK_NAME --template-body file://template/template_ec2.yaml --capabilities CAPABILITY_NAMED_IAM

cd $SOURCE_REPOSITORY/src

sleep 90s

echo ' Updating the Amazon ECR with the code'
docker build -t batch_processor .
docker tag batch_processor $(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.$REGION.amazonaws.com/$STACK_NAME-repository
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.$REGION.amazonaws.com
docker push $(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.$REGION.amazonaws.com/$STACK_NAME-repository

echo 'Updating sample S3 files to your account '$ACCOUNT_NUMBER
aws s3 --region $REGION cp $SOURCE_REPOSITORY/sample/sample.csv s3://$STACK_NAME-$ACCOUNT_NUMBER

cd $SOURCE_REPOSITORY