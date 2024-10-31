# Create an S3 bucket with versioning enabled using Terraform

## Pre-requisites
- Clone the repository
- Install Terraform
- AWS credentials

## Install Terraform
Use the following link to install Terraform: [Terraform Installation](https://developer.hashicorp.com/terraform/install)

### Once installed, verify the installation worked:

```bash
terraform --version
```
We are using Terraform version `1.5.5` for this guide. For Terraform version management, you can use a tool like [tfenv](https://github.com/tfutils/tfenv).

### Get AWS credentials:
To authenticate with AWS, you can use the AWS CLI or set the environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` in your terminal.

If you are using `AWS Identity Center` to manage your AWS accounts, you can find the credentials under the `account` -> `role` -> `Access keys` link.

# Terraform Configuration
## 1. Define the provider and version in the terraform configuration file:
Go to the directory of the `module/` where you will find the terraform configuration files and update the file named `version.tf` with the following content:
```hcl
terraform {
    required_version = "<= 1.5.5"
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.57.0"
        }
    }
}

provider "aws" {
  region = "eu-west-2"
}
```

Configuring the provider and version in the terraform configuration file is important as it allows Terraform to download the necessary provider plugins. The provider block configures the AWS provider to use the `eu-west-2` region.

Alternatively, you can configure the provider with credentials using the following block:
```hcl
provider "aws" {
  region     = "eu-west-2"
  access_key = "my-access-key"
  secret_key = "my-secret-key"
}

or 

provider "aws" {
  shared_config_files      = ["/Users/tf_user/.aws/conf"]
  shared_credentials_files = ["/Users/tf_user/.aws/creds"]
  profile                  = "customprofile"
}
```

Find more information on configuring the AWS provider [here](https://registry.terraform.io/providers/hashicorp/aws/latest/docs).


## 2. Create the S3 bucket resource and versioning configuration: 
Update the file named `main.tf` in the directory named `module/` and add the following content:

```hcl
resource "aws_s3_bucket" "terraform_guide_bucket" {
  bucket = var.bucket_name

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_guide_bucket.id

  versioning_configuration {
    status = var.versioning_status ? "Enabled" : "Disabled"
  }
}
```
Remember that bucket names must be unique across all of AWS. For example adding your account id to the bucket name can help ensure uniqueness. 

We reference the bucket resource `aws_s3_bucket.terraform_guide_bucket.id` to get the ID of the S3 bucket. The `versioning_configuration` block is used to enable versioning on the S3 bucket. This is called an explicit dependency.

We indicate input variables `var.bucket_name`, `versioning_status` and `var.tags` to pass the bucket name and tags to the module.

### Note:
While the `versioning_configuration.status` parameter supports `Disabled`, this value is only intended for creating or importing resources that correspond to unversioned S3 buckets. Updating the value from `Enabled` or `Suspended` to `Disabled` will result in errors as the AWS S3 API does not support returning buckets to an unversioned state.

`var.versioning_status ? "Enabled" : "Disabled"` is a conditional expression that checks the value of the `versioning_status` variable. If the value is `true`, the operator returns `"Enabled"`, otherwise it returns `"Disabled"`.


## 3. Create Access Control List (ACL) for the S3 bucket:
Continue to add the following content to the `main.tf` file:
```hcl
resource "aws_s3_bucket_ownership_controls" "acl" {
  bucket = aws_s3_bucket.terraform_guide_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "acl" {
  depends_on = [aws_s3_bucket_ownership_controls.acl]

  bucket = aws_s3_bucket.terraform_guide_bucket.id
  acl    = "private"
}
```
We can see how we can create implied dependencies between resources using the `depends_on` attribute. In this case, the `aws_s3_bucket_acl` resource depends on the `aws_s3_bucket_ownership_controls` resource.


## 4. Create the input variables file:
Update the file named `variables.tf` in the directory named `module/` and add the following content:
```hcl
variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "versioning_status" {
  description = "The versioning status of the S3 bucket"
  type        = bool
}

variable "tags" {
  description = "The tags to apply to the S3 bucket"
  type        = map(string)
  default    = null
}
```

Variables are used to pass values to the module. In this case, we are passing the `bucket_name`, `versioning_status` and `tags` to the module.

## 5. Create outputs for the S3 bucket module: 
Update the file named `outputs.tf` in the same directory as the `main.tf` file and add the following content:

```hcl

output "s3_bucket_id" {
  description = "The ID of the S3 bucket"
  value       = aws_s3_bucket.terraform_guide_bucket.id
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.terraform_guide_bucket.arn
}
```

We reference the `aws_s3_bucket.terraform_guide_bucket.id` and `aws_s3_bucket.terraform_guide_bucket.arn` to get the ID and ARN of the S3 bucket respectively.



## 6. Run Terraform commands
To run Terraform commands, navigate to the directory of the `root` where the terraform configuration file is located. 

The `root` directory contains the `main.tf` file that references the `module/` directory where the S3 bucket module is defined.

Update the `main.tf` file with inputs that are avaliable in the `variables.tf` file of the module.

```hcl
module "my_s3_bucket" {
  source = "./module/"

  bucket_name       = "<your-name-for-the-bucket>"
  versioning_status = true

  tags = {
    Environment = "Dev"
    Project     = "Infrastructure"
  }
}

output "bucket_id" {
  value = module.my_s3_bucket.s3_bucket_id
}

output "bucket_arn" {
  value = module.my_s3_bucket.s3_bucket_arn
}
```
We must reference the outputs from the module in the root module to access the outputs from the module.

The only values that need to be passed to the module are the `bucket_name` and `versioning_status`. The `tags` are optional and can be passed if needed.

### Initialize Terraform:
Running the following command will initialize Terraform and download the necessary providers:
```bash
terraform init
```

### Plan the changes to be applied:
Running the following command will show you the changes that Terraform will make to the infrastructure:
```bash
terraform plan
```

### Validate the plan:
Output from the planning should look like this:
```bash
Plan: 4 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + bucket_arn = (known after apply)
  + bucket_id  = (known after apply)
```

We can see that Terraform will add 4 resources to the infrastructure. When you run terraform plan it will present you with the execution plan. This will show you which resources are going to be `created`/`deleted` or `modified`. The following symbols indicated with the plan are:
```bash
  + created
  - deleted
  ~ updated

  example: 
  # module.my_s3_bucket.aws_s3_bucket_acl.acl will be created
  + resource "aws_s3_bucket_acl" "acl" {
      + acl    = "private"
      + bucket = (known after apply)
      + id     = (known after apply)
    }
```

### Apply the changes:
Running the following command will apply the changes to the infrastructure:
```bash
terraform apply
```
You will be prompted to confirm the changes. Type `yes` to apply the changes. Alternatively, you can run the command with the `-auto-approve` flag to automatically apply the changes without being prompted.

### Validate the output:
Output from the apply should look like this:
```bash
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

bucket_arn = "arn:aws:s3:::<your-name-for-the-bucket>"
bucket_id = "<your-name-for-the-bucket>"
```

We can see the outputs `bucket_arn` and `bucket_id` from the module that are being outputted from the root module.

## CONGRATULATIONS! 
You have successfully created an S3 bucket with versioning enabled using Terraform.


## 8. Change the versioning status:
We now want to change the object ownership to `BucketOwnerEnforced`. Update the resource `aws_s3_bucket_ownership_controls` found in `main.tf` file in the `module/` directory with the following content: 
```hcl

resource "aws_s3_bucket_ownership_controls" "acl" {
  bucket = aws_s3_bucket.terraform_guide_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
```

This will change the object ownership to `BucketOwnerEnforced` which means that the bucket owner will always own the objects in the bucket. ACLs no longer affect permissions to data in the S3 bucket.

### Plan the changes to be applied:
As we have already initialized Terraform, we can run the following command to show the changes that Terraform will make to the infrastructure:
```bash
terraform plan
```

### Validate the plan:
Output from the planning should look like this:
```bash
Terraform will perform the following actions:

  # module.my_s3_bucket.aws_s3_bucket_ownership_controls.acl will be updated in-place
  ~ resource "aws_s3_bucket_ownership_controls" "acl" {
        id     = "012345678900-terraform-beginners-guide"
        # (1 unchanged attribute hidden)

      ~ rule {
          ~ object_ownership = "BucketOwnerPreferred" -> "BucketOwnerEnforced"
        }
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```
The output shows that Terraform will update the `aws_s3_bucket_ownership_controls` resource in-place. The `object_ownership` attribute will be changed from `BucketOwnerPreferred` to `BucketOwnerEnforced`.

### Apply the changes:
Running the following command will apply the changes to the infrastructure:
```bash
terraform apply
```

### Validate the output:
Output from the apply should look like this:
```bash
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.

Outputs:

bucket_arn = "arn:aws:s3:::<your-name-for-the-bucket>"
bucket_id = "<your-name-for-the-bucket>"
```


## 7. Destroy
To destroy the resources created by Terraform, run the following command:
```bash
terraform destroy
```

### Validate that everything was destroyed:
Output from the planning should look like this:
```bash
Destroy complete! Resources: 4 destroyed.
```




# Using Community module
Now that you have created your own S3 bucket module, you can try and recreate it using the community module. 

### Before we begin: 
make sure to remove the `.terraform` directory, `terraform.tfstate` and `.terraform.lock.hcl` files from the root directory where you ran the terraform commands earlier.

Afterwards update the root module named `my_s3_bucket` with the following content:
```hcl

module "my_s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  version = "4.2.1"
  ## alternative reference 
  ## source = "git@github.com:terraform-aws-modules/terraform-aws-s3-bucket.git?ref=v4.2.1"

  bucket = "<your-name-for-the-bucket>"
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"

  versioning = {
    enabled = true
  }

  tags = {
    Environment = "Dev"
    Project     = "Infrastructure"
  }
}
```

You can see that the source reference has been updated to point to the community module `terraform-aws-modules/s3-bucket/aws`.

### Note:
If you want to experiment with different attributes of the module, you can if the options [here](https://github.com/terraform-aws-modules/terraform-aws-s3-bucket).

## Initialize Terraform:
Running the following command will initialize Terraform and download the necessary providers:
```bash
terraform init
```

## Plan the changes to be applied:
Running the following command will show you the changes that Terraform will make to the infrastructure:
```bash
terraform plan
```
### Validate the plan:
Output from the planning should look like this:
```bash
Plan: 5 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + bucket_arn = (known after apply)
  + bucket_id  = (known after apply)
```

### Apply the changes:
Running the following command will apply the changes to the infrastructure:
```bash
terraform apply
```

You will be prompted to confirm the changes. Type `yes` to apply the changes. Alternatively, you can run the command with the `-auto-approve` flag to automatically apply the changes without being prompted.

### Validate the output:
Output from the apply should look like this:
```bash
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

bucket_arn = "arn:aws:s3:::<your-name-for-the-bucket>"
bucket_id = "<your-id-for-the-bucket>"
```

### CONGRATULATIONS!
You have successfully created an S3 bucket with versioning enabled using the community module.

# Remember to clean up! 
To destroy the resources created by Terraform, run the following command:
```bash
terraform destroy
```

### Validate that everything was destroyed:
Output from the planning should look like this:
```bash
Destroy complete! Resources: 5 destroyed.
```