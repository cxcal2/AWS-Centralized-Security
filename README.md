# Central Security Orchestration

Production-ready Terraform solution for centralized AWS security management using AWS Config and Firewall Manager. Supports account-specific and resource-specific WAF policy targeting with OWASP LLM Top 10 protection.

**[WAF Policy Management Guide](WAF_POLICY_MANAGEMENT_GUIDE.md)** | **[Architecture Guide](docs/ARCHITECTURE_AND_RESOURCES.md)** | **[Deployment Guide](docs/DEPLOYMENT_CHECKLIST.md)** | **[Prerequisites](docs/PREREQUISITES.md)**

## Overview

Centralized security management solution that deploys AWS Config and Firewall Manager policies across an entire AWS Organization from a designated security account. Provides automated WAF protection and compliance monitoring while optimizing costs through intelligent account targeting.

### Architecture

![Central Security Orchestration Architecture](docs/Security_Arch.png)

#### Key Components:
- **Security Account**: Centralized management with AWS Config and Firewall Manager
- **Target Accounts**: Automatic WAF policy deployment and Config monitoring
- **Excluded Accounts**: Cost-optimized exclusion of specific account types
- **Organization-wide Coverage**: Single deployment protects entire organization

## Features

- **Centralized Management**: Deploy security policies from one account
- **Account-Specific Policies**: Target specific accounts without affecting others
- **Resource-Level Targeting**: Use tags to target specific ALBs within accounts
- **OWASP LLM Protection**: Pre-built rules for LLM/Bedrock security
- **Automated Protection**: WAF policies automatically applied to tagged resources
- **Cost Optimization**: Intelligent account exclusion patterns
- **Compliance Monitoring**: Organization-wide Config rule evaluation
- **Real-time Alerting**: CloudWatch alarms for policy violations
- **Scalable Architecture**: Supports large multi-account organizations

## WAF Policy Management

The module supports three main use cases for WAF policy management. See the comprehensive [WAF Policy Management Guide](WAF_POLICY_MANAGEMENT_GUIDE.md) for detailed instructions.

### Use Case 1: Creating New Policies

Deploy WAF protection to resources that don't have any WAF:

```hcl
enable_owasp_llm_rules = true

custom_waf_policies = [
  {
    name                        = "new-production-waf"
    resource_type               = "AWS::ElasticLoadBalancingV2::LoadBalancer"
    target_accounts             = ["123456789012"]
    resource_tags               = { Environment = "production" }
    enable_owasp_llm_protection = true
  }
]
```

### Use Case 2: Migrating Existing Policies

Migrate standalone WAF policies to centralized management:

**Steps:**
1. Export existing WAF policies (see findexisting_Waf/README.md)
2. Tag your resources
3. Configure custom_waf_policies in terraform.tfvars
4. Deploy with override_customer_waf_association = false
5. Validate side-by-side
6. Enable override mode and cleanup old policies

### Use Case 3: Managing Centralized Policies

Update, modify, or add new policies to existing deployment:

- Add new accounts to existing policies
- Modify rules in existing policies
- Add new policies for new resources
- Update policy configurations
- Manage global vs custom policies

See [WAF_POLICY_MANAGEMENT_GUIDE.md](WAF_POLICY_MANAGEMENT_GUIDE.md) for complete instructions on all use cases.

## Production Safety

This solution is designed for safe deployment in existing environments:
- Auto-detects existing FMS admin accounts
- Uses existing security account FMS admin if already configured  
- Skips creating duplicates to avoid disrupting existing policies
- Preserves existing policies when adding new target OUs
- Safe for production environments with existing FMS setups

## Quick Start

### Basic Deployment

```hcl
module "security_orchestration" {
  source = "./security-modules"
  
  # Organization settings
  organization_name  = "mycompany"
  config_bucket_name = "mycompany-security-config"
  
  # Service enablement
  enable_aws_config       = true
  enable_firewall_manager = true
  
  # Account targeting
  databricks_account_patterns = ["databricks", "spark", "ml"]
  
  # WAF configuration
  aws_managed_rules = {
    common_rule_set  = true
    known_bad_inputs = true
    ip_reputation    = true
  }
  
  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

### Quick Deployment

```bash
# 1. Clone repository
git clone <repository>
cd security-modules

# 2. Configure variables
cp terraform.tfvars.example terraform.tfvars
# Update: organization_name, delegated_admin_account_id, config_bucket_name

# 3. Deploy
terraform init && terraform apply

# 4. Verify deployment
terraform output deployment_summary
```

## How It Works

### AWS Config Module
Provides organization-wide compliance monitoring and resource tracking:

- Monitors security-relevant resources across all accounts
- Stores configuration data in centralized S3 bucket
- Excludes high-cost accounts based on patterns
- Provides organization-wide visibility through Config aggregator

### Firewall Manager Module
Manages WAF policies across the organization:

- Creates and deploys WAF rules to all target accounts
- Uses AWS Managed Rules for common threats
- Supports custom rules for specific requirements
- Protects CloudFront, ALB, and API Gateway resources
- Provides compliance monitoring and alerting

## Configuration

### Account Targeting

```hcl
# Pattern-based exclusion (recommended)
databricks_account_patterns = [
  "databricks", "spark", "ml", "analytics"
]

# Explicit exclusions
additional_excluded_accounts = ["111111111111"]

# OU-based targeting
enable_ou_targeting = true
target_organizational_units = ["ou-root-123456789"]
```

### WAF Rules Configuration

```hcl
# AWS Managed Rules
aws_managed_rules = {
  common_rule_set    = true   # OWASP Top 10 - Always enable
  known_bad_inputs   = true   # Malicious patterns - Always enable
  ip_reputation      = true   # Bad IP blocking - Recommended
  sql_injection      = true   # Enable for database apps
  linux_rule_set     = true   # Enable for Linux apps
  php_rule_set       = false  # Enable for PHP apps
  wordpress_rule_set = false  # Enable for WordPress sites
}

# Custom Rules
custom_rules = {
  rate_limiting = {
    enabled   = true
    threshold = 2000      # Requests per 5-minute window
    action    = "BLOCK"
  }
  geo_blocking = {
    enabled   = true
    countries = ["CN", "RU", "KP", "IR"]
    action    = "BLOCK"
  }
  ip_whitelist = {
    enabled = true
    ips     = ["203.0.113.0/24", "198.51.100.0/24"]
  }
}
```

## Cost Optimization

### Cost Comparison

| Deployment Model | Per Account Cost | 10 Account Cost | Notes |
|-----------------|------------------|-----------------|-------|
| Individual Account Setup | $150-500 | $1,500-5,000 | Manual setup per account |
| Centralized Solution | $10-50 | $100-500 | Automated organization-wide |

### Cost Reduction Strategies
- **Pattern-based Exclusions**: Automatically excludes high-cost account types
- **Resource-specific Monitoring**: Only tracks security-relevant resources
- **Centralized Deployment**: Single deployment covers entire organization
- **Intelligent Targeting**: Focuses on accounts that benefit from protection

## Monitoring & Compliance

### CloudWatch Dashboards
- **Security Overview**: `{organization_name}-SecurityOrchestration`
- **Config Monitoring**: Organization-wide Config status
- **Firewall Manager**: Policy compliance and WAF metrics

### Compliance Monitoring
```bash
# Check deployment status
terraform output deployment_summary

# Verify policy compliance
aws fms list-policies
aws fms get-compliance-detail --policy-id <policy-id>

# Monitor Config status
aws configservice describe-configuration-aggregators
```

### Alerting Setup
```hcl
# Enable compliance alarms
enable_compliance_alarms = true
compliance_notification_emails = ["security@company.com"]

# Creates alerts for:
# - Policy compliance drops below 95%
# - Config recorder failures
# - High WAF block rates
# - Unusual geographic patterns
```

## Rule Management

### Quick Rule Updates

```hcl
# Add new AWS Managed Rule
aws_managed_rules = {
  common_rule_set  = true
  known_bad_inputs = true
  ip_reputation    = true
  sql_injection    = true    # ← Add this line
}

# Update rate limiting threshold
custom_rules = {
  rate_limiting = {
    enabled   = true
    threshold = 5000    # ← Increase threshold
    action    = "BLOCK"
  }
}
```

### Emergency Procedures

```bash
# Disable problematic rule
aws_managed_rules = {
  ip_reputation = false
}

# Switch to monitoring mode
custom_rules = {
  rate_limiting = {
    enabled = true
    action  = "COUNT"  # Change from BLOCK to COUNT
  }
}
```

## Pipeline Deployment

### GitHub Actions Setup

The repository includes production-ready GitHub Actions workflows for automated deployment:

#### Prerequisites

1. **Security Admin Account Credentials for GitHub Actions**:
```bash
# Use Security Admin Account credentials (not Organization Admin)
# Required permissions for Security Admin Account:
# - AWS Config: Full access for configuration management
# - Firewall Manager: Full access for WAF policy management
# - S3: Access for Terraform state bucket
# - DynamoDB: Access for state locking

# GitHub Actions will use these credentials:
# AWS_ACCESS_KEY_ID: Security Admin Account access key
# AWS_SECRET_ACCESS_KEY: Security Admin Account secret key
# AWS_SESSION_TOKEN: Optional for temporary credentials
```

2. **S3 Backend for Terraform State**:
```bash
# Create S3 bucket for Terraform state (using Security Admin Account)
DATE_SUFFIX=$(date +%Y%m%d)
BUCKET_NAME="your-org-terraform-state-security-$DATE_SUFFIX"

aws s3 mb s3://$BUCKET_NAME

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket $BUCKET_NAME \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock-security \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

3. **GitHub Repository Secrets**:
```bash
# Required secrets in GitHub repository settings (Security Admin Account):
AWS_ACCESS_KEY_ID=security-admin-access-key-id
AWS_SECRET_ACCESS_KEY=security-admin-secret-access-key
AWS_SESSION_TOKEN=security-admin-session-token  # Optional for temporary credentials
TF_STATE_BUCKET=your-org-terraform-state-security-YYYYMMDD  # Optional, auto-generated with date suffix if not provided
```

#### Workflow Configuration

The deployment workflow supports:
- **Automatic deployment** on push to main/production branches
- **Manual deployment** with environment selection
- **Pull request validation** with plan preview
- **Security scanning** with Checkov
- **Multi-environment support** (production, staging, development)

#### Deployment Commands

```bash
# Automatic deployment (push to main)
git push origin main

# Manual deployment via GitHub UI
# Go to Actions -> Deploy Central Security Orchestration -> Run workflow
# Select: Action=apply, Environment=production

# Emergency destroy (manual only)
# Actions -> Deploy Central Security Orchestration -> Run workflow
# Select: Action=destroy, Environment=production
```

### OU-Based Targeting

For organizations using Organizational Units:

```hcl
# Enable OU targeting instead of account-based
enable_ou_targeting = true

# Target specific OUs
target_organizational_units = [
  "ou-root-123456789",    # Root OU
  "ou-1234567890abcdef",  # Production OU
  "ou-abcdef1234567890"   # Development OU
]

# Exclude specific OUs
excluded_organizational_units = [
  "ou-databricks123456",  # Databricks OU
  "ou-analytics1234567"   # Analytics OU
]
```

### Pipeline Best Practices

1. **Environment Separation**:
```bash
# Use separate state files per environment
terraform.tfstate.d/
├── production/
├── staging/
└── development/
```

2. **Approval Gates**:
```yaml
# Add to .github/workflows/deploy-security.yml
environment:
  name: production
  url: https://console.aws.amazon.com/fms
```

3. **Monitoring Integration**:
```bash
# Post-deployment validation
aws fms list-policies --query 'PolicyList[?PolicyName==`mycompany-cloudfront-waf-policy`]'
aws configservice describe-configuration-aggregators
```

## Deployment Examples

### Minimal (Basic Protection)
```hcl
organization_name = "mycompany"
enable_aws_config = true
enable_firewall_manager = true

aws_managed_rules = {
  common_rule_set  = true
  known_bad_inputs = true
  ip_reputation    = true
}
```

### Production (Comprehensive)
```hcl
organization_name = "mycompany"
enable_aws_config = true
enable_firewall_manager = true
enable_waf_logging = true
enable_automatic_remediation = true

aws_managed_rules = {
  common_rule_set    = true
  known_bad_inputs   = true
  ip_reputation      = true
  sql_injection      = true
  linux_rule_set     = true
}

custom_rules = {
  rate_limiting = {
    enabled   = true
    threshold = 2000
  }
  geo_blocking = {
    enabled   = true
    countries = ["CN", "RU", "KP"]
  }
}
```

## Troubleshooting

### Firewall Manager Admin Not Set
```bash
aws fms put-admin-account --admin-account "$(aws sts get-caller-identity --query Account --output text)"
```

### Organizations Service Access Disabled
```bash
aws organizations enable-aws-service-access --service-principal config.amazonaws.com
aws organizations enable-aws-service-access --service-principal fms.amazonaws.com
```

### High Config Costs
```bash
# Check excluded accounts
terraform output excluded_accounts

# Review cost savings
terraform output cost_savings_summary
```

## Documentation

- **[Complete Documentation](docs/README.md)** - Documentation overview
- **[Architecture & Resources](docs/ARCHITECTURE_AND_RESOURCES.md)** - Detailed architecture and resources
- **[Prerequisites](docs/PREREQUISITES.md)** - Requirements and setup validation
- **[Deployment Checklist](docs/DEPLOYMENT_CHECKLIST.md)** - Step-by-step deployment guide
- **[Rule Management Guide](docs/RULE_MANAGEMENT_GUIDE.md)** - Comprehensive rule documentation
- **[Rule Quick Reference](docs/RULE_QUICK_REFERENCE.md)** - Common commands and procedures
- **[AWS Config Module](aws-config/README.md)** - Config foundation details
- **[Firewall Manager Module](firewall-manager/README.md)** - WAF policy management

## Outputs

```hcl
# Deployment information
deployment_summary      = "Complete deployment status"
target_accounts        = "List of protected accounts"
excluded_accounts      = "List of excluded accounts"

# Security resources
cloudfront_waf_policy_id = "CloudFront WAF policy ID"
alb_waf_policy_id       = "ALB WAF policy ID"

# Cost optimization
cost_savings_summary    = "Detailed cost savings report"
```

## Support

- **Issues**: Open GitHub issue for bugs or feature requests
- **Documentation**: Check module-specific READMEs for detailed configuration
- **Troubleshooting**: Review CloudWatch dashboards and Terraform outputs
- **Emergency**: Use emergency procedures for quick rule changes

---

**Result**: Organization-wide security protection with centralized management and cost optimization.