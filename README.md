# CDE - uloha - Hrkalová

The templates of dce-iac-testing and dce-lab-projects were used.

## 1) Start terraform 
This will start plain VMs - due tu max nebula VMs there are set just  2 backends. It is configurable in variables.tf

 - You need to pass correct credentials for your opennebula in terraform.tfvars

```
terraform init
terraform plan
terraform apply
```
Terraform init will install the needed resources
Terraform plan will create terraform.tfstate
 - You need to pass the id_ecdsa key 
Terraform apply will create the opennebula VMs
 - You need to pass the id_ecdsa key

Then VM's should be created. When it is running longer than expected, it might get an error on remote exec, the init scripts will get timeout. It happened only twice, but I would like to add that here. But generally they are succesfully created.

## 2) Start ansible
This will pass the configurations of backend and frontend to plain VMs on opennebula. 
There are 3 roles in ansible
  - frontend - this pass the configuration of frontend (such as html cnf files) and set up the nginx
  - backend - this pass the configuration of backend using dockerfile provided in demo-3
  - prepare - all needed resources will be download or installed - this is the first role that is running

```
ansible-playbook -i dynamic_inventories/inventory ansible/main-play.yml 
```

Then the VMs should be configured, you can check by typin the ip in your browser

This will show the frontend HTML
```
147.228.173.127
```
This will show the nginx load balancer
```
http://147.228.173.127/service-api
```
