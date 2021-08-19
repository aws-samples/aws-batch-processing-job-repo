
# Orchestrating an Application Process with AWS Batch using AWS CloudFormation

The sample provided spins up an application orchestration using AWS Services like AWS Simple Storage Service (S3), AWS Lambda and AWS DynamoDB. Amazon Elastic Container Registry (ECR) is used as the Docker container registry. Once the CloudFormation stack is spun up, the downloaded code can be checked in into your AWS CodeCommit repository (built as part of the stack) which would trigger the build to deploy the image to Amazon ECR. AWS Batch will be triggered by the lambda when a sample CSV file is dropped into the S3 bucket. 

**As part of this blog we will do the following.**

1.	Run the CloudFormation template (command provided) to create the necessary infrastructure

2.	Set up the Docker image for the job
    - Build a Docker image
    - Tag the build and push the image to the repository

3.	Drop the CSV into the S3 bucket (Copy paste the contents and create them as a sample file (“Sample.csv”)

4.	Notice the Job runs and performs the operation based on the pushed container image. The job parses the CSV file and adds each row into DynamoDB.

![Alt text](Orchestrating%20an%20application%20process%20with%20AWS%20Batch.png?raw=true "Title")

### Design Considerations

1. Provided CloudFormation template has all the services (refer diagram below) needed for this exercise in one single template. In a production scenario, you may ideally want to split them into different templates (nested stacks) for easier maintenance.

2. Lambda uses Batch Jobs’ JobDefinition, JobQueue - Version as parameters. Once the Cloudformation stack is complete, this can be passed as input parameters and set as environment variables for the Lambda. Otherwise, When you deploy subsequent version of the jobs, you may need to manually change the queue definition:version.

3. Below example lets you build, tag, pushes the docker image to the repository (created as part of the stack). Optionally this can be done with the AWS CodeBuild building from the repository and shall push the image to AWS ECR.

### Steps

1. Download this repository - We will refer this as SOURCE_REPOSITORY

```
  $ git clone https://github.com/aws-samples/aws-batch-processing-job-repo
```

2. Execute the below commands to spin up the infrastructure cloudformation stack. This stack spins up all the necessary AWS infrastructure needed for this exercise

```
$ cd aws-batch-processing-job-repo

$ aws cloudformation create-stack --stack-name batch-processing-job --template-body file://template/template.yaml --capabilities CAPABILITY_NAMED_IAM
```

3. You can run the application in two different ways

    *  #### CI/CD implementation. 

        ##### This steps allows you to copy the contents from source git repo and trigger deployment into your repository
            * The above command would have created a git repository in your personal account. Make sure to replace your region below accordingly
            * $ git clone https://git-codecommit.us-east-1.amazonaws.com/v1/repos/batch-processing-job-repo
            * cd batch-processing-job-repo
            * copy all the contents from SOURCE_REPOSITORY (from step 1) and paste inside this folder
            * $ git add .
            * $ git commit -m "commit from source"
            * $ git push 

    * #### Build and run from local desktop. 
    
        ##### Containarize the provided python file and push it to the Amazon ECR. Dockerfile provided as part of this exercise. In this steps you push the code (provided as part of this exercise) to the repository that was built as part of CloudFormation stack

    * RUN the below commands to dockerize the python file 

        i. Make sure to replace your account number, region accordingly

        ii. Make sure to have Docker daemon running in your local computer
        
        
        ```
        $ cd SOURCE_REPOSITORY (Refer step 1)
        $ cd src

        # get the login creds and copy the below output and paste/run on the command line
        $ aws ecr get-login --region us-east-1 --no-include-email

        # Build the docker image locally, tag and push it to the repository
        $ docker build -t batch_processor .
        $ docker tag batch_processor $(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.us-east-1.amazonaws.com/batch-processing-job-repository
        $ docker push $(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.us-east-1.amazonaws.com/batch-processing-job-repository

        ```

### Testing

Make sure to complete the above step. You can review the image in AWS Console > ECR - "batch-processing-job-repository" repository

1. AWS S3 bucket - batch-processing-job-<YOUR_ACCOUNT_NUMBER> is created as part of the stack.
2. Drop the provided Sample.CSV into the S3 bucket. This will trigger the Lambda to trigger the AWS Batch

    ```
    aws s3 cp sample/sample.csv s3://batch-processing-job-$(aws sts get-caller-identity --query 'Account' --output text)
    ```
3. In AWS Console > Batch, Notice the Job runs and performs the operation based on the pushed container image. The job parses the CSV file and adds each row into DynamoDB.
4. In AWS Console > DynamoDB, look for "batch-processing-job" table. Note sample products provided as part of the CSV is added by the batch

### Code Cleanup

1. AWS Console > S3 bucket - batch-processing-job-<YOUR_ACCOUNT_NUMBER> - Delete the contents of the file
2. AWS Console > ECR - batch-processing-job-repository - delete the image(s) that are pushed to the repository
3. run the below command to delete the stack.

    ```
    $ aws cloudformation delete-stack --stack-name batch-processing-job

    ```
## License

This library is licensed under the MIT-0 License. See the LICENSE file.
