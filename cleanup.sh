#!/bin/bash

SOURCE_REPOSITORY=$PWD
STACK_NAME=fargate-batch-job

REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
ACCOUNT_NUMBER=$(aws sts get-caller-identity --query 'Account' --output text)

echo 'Deleting Amazon ECR and S3 data'
aws ecr batch-delete-image --repository-name $STACK_NAME-repository --image-ids imageTag=latest
aws ecr batch-delete-image --repository-name $STACK_NAME-repository --image-ids imageTag=untagged

aws s3 --region $REGION rm s3://$STACK_NAME-$ACCOUNT_NUMBER --recursive

echo 'Cleaninup the CloudFormation Stack'
aws cloudformation delete-stack --stack-name $STACK_NAME

echo 'CloudFormation Stack - '$STACK_NAME ' Steps completed successfully!'