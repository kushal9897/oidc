.PHONY: help init start-vault stop-vault bootstrap deploy-qa deploy-prod clean

help:
	@echo "Available commands:"
	@echo "  make init        - Initialize the project"
	@echo "  make start-vault - Start Vault server"
	@echo "  make stop-vault  - Stop Vault server"
	@echo "  make bootstrap   - Run Terraform bootstrap"
	@echo "  make deploy-qa   - Deploy QA environment"
	@echo "  make deploy-prod - Deploy Production environment"
	@echo "  make clean       - Clean up all resources"

init:
	@chmod +x scripts/*.sh
	@./scripts/init-project.sh

start-vault:
	@./scripts/start-vault.sh

stop-vault:
	@if [ -f vault.pid ]; then \
		kill `cat vault.pid` && rm vault.pid; \
		echo "Vault stopped"; \
	fi
	@if [ -f ngrok.pid ]; then \
		kill `cat ngrok.pid` && rm ngrok.pid; \
		echo "Ngrok stopped"; \
	fi

bootstrap:
	@cd bootstrap && terraform init && terraform apply

deploy-qa:
	@cd environments/qa && terraform init && terraform apply

deploy-prod:
	@cd environments/production && terraform init && terraform apply

clean:
	@echo "Cleaning up..."
	@make stop-vault
	@rm -rf vault-data/
	@rm -f vault-keys.json
	@rm -rf */.terraform/
	@rm -f */terraform.tfstate*
	@echo "Cleanup complete"