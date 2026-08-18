# App Terraform

Demo Infrastructure-as-Code project that provisions a single S3 bucket in
a real AWS account using Terraform, built and applied through Jenkins.

## Pipeline

`Checkout` -> `Resolve Environment` -> `Terraform Init` -> `Terraform Validate` -> `Terraform Plan` -> `Terraform Apply` (main branch only).

Requires a Jenkins credential `aws-cred` (kind "Username with password":
username = AWS Access Key ID, password = AWS Secret Access Key).

## Local usage

```
terraform init
terraform plan -var="environment=dev"
terraform apply -var="environment=dev"
```

## Files

`main.tf` provider + S3 bucket resource. `variables.tf` region / bucket
name prefix / environment inputs. `outputs.tf` bucket name / ARN /
region. `Jenkinsfile` CI/CD pipeline.
