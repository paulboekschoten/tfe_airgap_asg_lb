# Terraform Enterprise Airgapped installation with Autoscaling group, Load balancer and valid certificates on AWS  
This repository installs an Airgapped Terraform Enterprise (TFE) with valid certificates in AWS on a Ubuntu virtual machine.  

This terraform code creates
- A VPC
- Subnets
- Internet gateway
- An Elastic IP
- NAT gateway
- Route Table entry
- Key pair
- Security group
- Security group rules
- S3 Buckets
- PostgreSQL Database
- A Route53 DNS entry
- Valid certificates
- Target groups
- Load balancer
  - Listeners
- Launch template
  - Ubuntu virtual machine (22.04)
  - Replicated configuration
  - TFE settings json
  - Install TFE airgapped
  - TFE Admin account
- Auto scaling group



# Diagram
![](diagram/tfe_airgapped.png)

# Prerequisites
 - An AWS account with default VPC and internet access.
 - A TFE Airgap installation file
 - A TFE license

# How to install airgapped TFE with ASG, LB and valid certficates on AWS
- Clone this repository.  
```
git clone https://github.com/paulboekschoten/tfe_airgap_asg_lb.git
```

- Go to the directory 
```
cd tfe_airgap_asg_lb
```
- Save your TFE license in `config/license.rli`.  

- Save your airgap file in `files/`.  

- Rename `terraform.tfvars_example` to `terraform.tfvars`.  
```
mv terraform.tfvars_example terraform.tfvars
```

- Change the values in `terraform.tfvars` to your needs.

- Set your AWS credentials
```
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export AWS_SESSION_TOKEN=
```

- Terraform initialize
```
terraform init
```
- Terraform plan
```
terraform plan
```

- Terraform apply
```
terraform apply
```

TODO: set to correct output
Terraform output should show 37 resources to be created with output similar to below. 
```
Apply complete! Resources: 37 added, 0 changed, 0 destroyed.

Outputs:

public_ip = "15.236.36.65"
replicated_dashboard = "https://tfe-airgap-paul.tf-support.hashicorpdemo.com:8800"
ssh_login = "ssh -i tfesshkey.pem ubuntu@tfe-airgap-paul.tf-support.hashicorpdemo.com"
tfe_login = "https://tfe-airgap-paul.tf-support.hashicorpdemo.com"
```

- Go to the Replicated dashboard. (Can take 10 minutes to become available.)  
- Click on the open button to go to TFE of go to the `tfe_login` url.  

# TODO
- [ ] Create manually
- [ ] Add diagram
- [ ] Create VPC
- [ ] Create Subnets
- [ ] Create Internet gateway
- [ ] Create EIP
- [ ] Create NAT gateway
- [ ] Change default Route Table
- [ ] Create private rout table
- [ ] Create Key pair
- [ ] Create security group
- [ ] Create a security group rules
- [ ] Create DNS record
- [ ] Create valid certificate
- [ ] Create S3 buckets
- [ ] Create PostgreSQL database
- [ ] Create Target groups
- [ ] Create Load balancer
- [ ] Create Listeners
- [ ] Create Launch template
  - [ ] Create settings.json
  - [ ] Create replicated.conf
  - [ ] Copy certificates
  - [ ] Copy airgap file
  - [ ] Copy license.rli
  - [ ] Create admin user
- Create Auto scaling group
- [ ] Documentation

# DONE
