# control-ec2
control ec2 is a server automation to control a python server deployed on lambda function using api gateway

![alt text](https://github.com/ehabshaaban/terraform-challenge/blob/main/infrastructure.png)

## Setup
The following is required:

- Terraform v1.2.2
- GoLang v1.18.3

These enviroment variables are required:

- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
## Deploy
```
terraform init
terraform apply --auto-approve
```
## Test
```
cd test && go test -v -timeout 3000s infra_test.go
```
## Destroy
```
terraform destroy --auto-approve
```
## Technical Description
Terraform script will do the following:

- Create ec2 instance with default tags (You can change it from ```variables.tf```)
- Create s3 bucket with python server
- Deploy python server on lambda function
- Create two api gateway endpoints to communicate with lambda \
```/stop``` will stop ec2 instance \
```/tags``` will get ec2 tags
## Github Workflow
On every push for main and develop will trigger ```test-infra``` it will run the test (Will be locked only for main)

Environment variables are hooked up as secrets like the following:
```
env:
  AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
  AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```