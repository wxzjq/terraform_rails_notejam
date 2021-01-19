
Deploy the application to `production` environment run the following command

`$ terraform plan --var-file=production.tfvars`

After successfully creating the plan run the following command

`$ terraform apply --var-file=production.tfvars`

This will start creating your AWS infrastructure for the application and will success with providing url for the application loadbalancer using the following command

`$ terraform output alb_dns_name`
