# AWS Student Management API  

A serverless API for managing student data, built using **AWS Lambda**, **API Gateway**, and **DynamoDB**.  

## Prerequisites

Before you begin, ensure you have met the following requirements:

- You have an AWS account with the necessary permissions.
- You have Terraform installed on your local machine.
- You have configured AWS CLI with your credentials.
- You have a GitHub account and repository set up.

## Project Structure

The repository is organized into several key directories:

- **.github/workflows**: Contains the GitHub Actions workflow file (`apply.yml`) that automates the deployment process.
- **lambda**: Contains python code files for lambda functions.
- **main.tf**: Contains the Terraform configuration for creating lambda function, dynamodb table, api, and necessary iam roles.

## Project Overview  

This project demonstrates a scalable and cost-efficient solution for managing student information, leveraging modern cloud services and automation tools:  

- **Serverless Architecture**: Built using AWS Lambda and API Gateway to eliminate the need for traditional server management.  
- **Database Integration**: Uses AWS DynamoDB for fast and reliable NoSQL data storage.  
- **Secure Access**: Implements IAM policies to ensure only authorized users can access the API.  
- **Automation**: Infrastructure provisioning and deployment are automated using **Terraform** and **GitHub Actions**.    
 

### Architecture Overview  
- **AWS Lambda**: Handles the API logic and execution.  
- **API Gateway**: Serves as the entry point for external requests to the API.  
- **DynamoDB**: Stores and manages student data securely and efficiently.

## Workflow

1. **Terraform Configuration**: The `main.tf` contains the configuration files to create the S3 bucket and configure it for static website hosting. This includes setting up the bucket policy and enabling website hosting.
2. **GitHub Actions**: The workflow file (`deploy.yml`) in the `.github/workflows` directory automates the process of deploying the static website to S3. It uses the AWS credentials stored as GitHub Secrets to authenticate and upload the website files.


For further details or to explore the code, feel free to browse the repository.  
