terraform {
  backend "s3" {
    # Backend configuration will be provided via CLI or environment variables
    # bucket         = "your-org-terraform-state-security"
    # key            = "security-orchestration/production/terraform.tfstate"
    # region         = "us-east-1"
    # dynamodb_table = "terraform-state-lock-security"
    # encrypt        = true
    #
  }
}