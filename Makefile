
deploy-argops:
	@echo "This setup will provision default values witin the tf file - use with causion "
	@echo "Initiating local lock and state (Do not modify)"
	terraform init
	@echo "Running Plan"
	terraform plan
	@echo "Running Apply with autoapprove"
	terraform apply -auto-approve
destroy-argops:
	@echo "This will destroy your stack"
	terraform destroy -auto-approve
