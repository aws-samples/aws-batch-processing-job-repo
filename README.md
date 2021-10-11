
# Orchestrating an Application Process with AWS Batch using AWS CloudFormation

The sample provided spins up an application orchestration using AWS Services like AWS Simple Storage Service (S3), AWS Lambda and AWS DynamoDB. Amazon Elastic Container Registry (ECR) is used as the Docker container registry. AWS Batch will be triggered by the lambda when a sample CSV file is dropped into the S3 bucket. 

In the previous version of this blog (refer "template_ec2.yaml" the AWS Batch infrastructure was spin up using Managed EC2 compute environment). With fully serverless batch computing with AWS Batch Support for AWS Farage introduced last year, AWS Fargate can be used with AWS Batch to run containers without having to manage servers or clusters of Amazon EC2 instances. With AWS Fargate, you no longer have to provision, configure, or scale clusters of virtual machines to run containers. This removes the need to choose server types, decide when to scale your clusters, or optimize cluster packing

**As part of this blog we will do the following.**

1.	Run the CloudFormation template (command provided) to create the necessary infrastructure

2.	Set up the Docker image for the job
    - Make sure the Docker service is running
    - Build a Docker image
    - Tag the build and push the image to the repository

3.	Drop the CSV into the S3 bucket (Copy paste the contents and create them as a sample file (“Sample.csv”)

4.	Notice the Job runs and performs the operation based on the pushed container image. The job parses the CSV file and adds each row into DynamoDB.

![Alt text](aws-fargate-batch-application.png?raw=true "Title")

### Design Considerations

1. Provided CloudFormation template has all the services (refer diagram below) needed for this exercise in one single template. In a production scenario, you may ideally want to split them into different templates (nested stacks) for easier maintenance.

2. Example solution provided here lets you build, tag, pushes the docker image to the repository (created as part of the stack). Optionally this can be done with the AWS CodeBuild building from the repository and shall push the image to AWS ECR.

### Steps

1. Download this repository - We will refer this as SOURCE_REPOSITORY

```
  $ git clone https://github.com/aws-samples/aws-batch-processing-job-repo
```

2. Execute the below commands to spin up the infrastructure cloudformation stack. This stack spins up all the necessary AWS infrastructure needed for this exercise. Optionally "exec.sh" script provided does all the following. Note: "exec_ec2.sh" is optionally provided to run the previous version of the blog

```
$ cd aws-batch-processing-job-repo

$ STACK_NAME=fargate-batch-job

$ aws cloudformation create-stack --stack-name $STACK_NAME --parameters ParameterKey=StackName,ParameterValue=$STACK_NAME --template-body file://template/template.yaml --capabilities CAPABILITY_NAMED_IAM

```

3. A simple python application is provided (in "src" folder). This can be Docker containerized and pushed to the AWS Elastic Container Registry that was created in the above infrastructure

    ```
    $ STACK_NAME=fargate-batch-job

    $ REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')

    $ ACCOUNT_NUMBER=$(aws sts get-caller-identity --query 'Account' --output text)

    $ SOURCE_REPOSITORY=$PWD

    $ docker build -t batch_processor .

    $ docker tag batch_processor $(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.$REGION.amazonaws.com/$STACK_NAME-repository

    $ aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.$REGION.amazonaws.com

    $ docker push $(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.$REGION.amazonaws.com/$STACK_NAME-repository


    ```


### Testing

Make sure to complete the above step. You can review the image in AWS Console > ECR - "fargate-batch-job" repository

1. AWS S3 bucket - fargate-batch-job-<YOUR_ACCOUNT_NUMBER> is created as part of the stack.
2. Drop the provided Sample.CSV into the S3 bucket. This will trigger the Lambda to trigger the AWS Batch or run the below command

    ```
    aws s3 --region $REGION cp $SOURCE_REPOSITORY/sample/sample.csv s3://$STACK_NAME-$ACCOUNT_NUMBER
    ```
3. In AWS Console > Batch, Notice the Job runs and performs the operation based on the pushed container image. The job parses the CSV file and adds each row into DynamoDB.
4. In AWS Console > DynamoDB, look for "fargate-batch-job" table. Note sample products provided as part of the CSV is added by the batch

### Code Cleanup

Provided "cleanup.sh" script will remove the Amazon S3 files, Amazon ECR repository images and the AWS CloudFormation stack that was spun up as part of previous steps.  

Alternatively, below steps can be run manually to clean up the environment

1. AWS Console > S3 bucket - fargate-batch-job-<YOUR_ACCOUNT_NUMBER> - Delete the contents of the file
2. AWS Console > ECR - fargate-batch-job-repository - delete the image(s) that are pushed to the repository
3. run the below command to delete the stack.

    ```
    $ aws cloudformation delete-stack --stack-name fargate-batch-job

    ```
 4. To perform all the above steps in CLI

    ```
    $ SOURCE_REPOSITORY=$PWD
    $ STACK_NAME=fargate-batch-job

    $ REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')

    $ ACCOUNT_NUMBER=$(aws sts get-caller-identity --query 'Account' --output text)

    $ aws ecr batch-delete-image --repository-name $STACK_NAME-repository --image-ids imageTag=latest

    $ aws ecr batch-delete-image --repository-name $STACK_NAME-repository --image-ids imageTag=untagged

    $ aws s3 --region $REGION rm s3://$STACK_NAME-$ACCOUNT_NUMBER --recursive

    $ aws cloudformation delete-stack --stack-name $STACK_NAME

    ```

### References
1. New – Fully Serverless Batch Computing with AWS Batch Support for AWS Fargate - https://aws.amazon.com/blogs/aws/new-fully-serverless-batch-computing-with-aws-batch-support-for-aws-fargate/

2. AWS Batch on AWS Fargate - https://docs.aws.amazon.com/batch/latest/userguide/fargate.html

## License

This library is licensed under the MIT-0 License. See the LICENSE file.
