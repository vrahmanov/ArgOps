# ArgOps
## Terraform
````
0 terraform fmt
1 terraform init 
2 terraform plan -var-file=fixtures.us-east-2.tfvars
3 terraform apply -var-file=fixtures.us-east-2.tfvars
````
## Best practices to further implement if needed
````
create s3 state bucket
create DynamoDb lock table
add PR fmt check + plan ( set secrets from github secrets) -> approver allowes master to be auto-approved and deployed
add master\main only workflow to deploy from ( no other branch is allowed to decline state confusion) 
notification workflow (failure - git blame annotation) 
````
## Issues identified along the way 
```
error : Error syncing load balancer: failed to ensure load balancer: Multiple tagged security groups found for instance i-XXXXXXXXX
solution : 
```

## 