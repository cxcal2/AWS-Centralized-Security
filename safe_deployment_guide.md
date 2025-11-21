# Safe Deployment Guide

## Production Safety Considerations

This guide outlines safe deployment practices for the Central Security Orchestration solution in production environments.

## Pre-Deployment Safety Checks

### 1. Existing FMS Admin Detection
```bash
# Check if FMS admin already exists
aws fms get-admin-account

# If admin exists, set create_fms_admin_account = false
```

### 2. Service Access Verification
```bash
# Verify Organizations service access
aws organizations list-aws-service-access-for-organization

# Required services:
# - config.amazonaws.com
# - fms.amazonaws.com
```

### 3. Account Validation
```bash
# Verify target account IDs are correct
aws organizations list-accounts --query 'Accounts[].{Id:Id,Name:Name}' --output table

# Verify OU IDs are correct
aws organizations list-organizational-units-for-parent --parent-id ROOT_ID
```

## Safe Configuration Practices

### 1. Variable Configuration
```hcl
# Use variables instead of hardcoded values
delegated_admin_account_id = var.security_account_id
ou_target_accounts        = var.target_account_list

# Set safe defaults
create_fms_admin_account = false  # Prevent accidental admin creation
force_destroy_bucket     = false # Prevent accidental data loss
```

### 2. Account Exclusion Patterns
```hcl
# Use patterns instead of hardcoded account IDs
databricks_account_patterns = [
  "databricks",
  "analytics", 
  "ml-*"
]

# Avoid hardcoded exclusions
additional_excluded_accounts = []  # Use patterns instead
```

### 3. Gradual Rollout
```hcl
# Start with limited scope
enable_ou_targeting = true
target_organizational_units = [
  "ou-sandbox-only"  # Start with non-production
]

# Expand gradually
# target_organizational_units = [
#   "ou-sandbox",
#   "ou-development",
#   "ou-production"  # Add after testing
# ]
```

## Deployment Safety Steps

### 1. Plan Review
```bash
# Always review plan before applying
terraform plan -out=deployment.plan

# Review all resources being created/modified
terraform show deployment.plan
```

### 2. Backup Existing Configuration
```bash
# Export existing FMS policies
aws fms list-policies --query 'PolicyList[].{Id:PolicyId,Name:PolicyName}' --output json > existing-policies.json

# Export existing Config rules
aws configservice describe-config-rules --query 'ConfigRules[].{Name:ConfigRuleName,State:ConfigRuleState}' --output json > existing-config-rules.json
```

### 3. Staged Deployment
```bash
# Deploy in stages
terraform apply -target=module.aws_config
# Verify Config deployment

terraform apply -target=module.firewall_manager
# Verify Firewall Manager deployment

terraform apply
# Complete deployment
```

## Post-Deployment Verification

### 1. Service Status Verification
```bash
# Verify Config service
aws configservice describe-configuration-recorders
aws configservice describe-configuration-recorder-status

# Verify FMS policies
aws fms list-policies
aws fms get-compliance-detail --policy-id POLICY_ID
```

### 2. Resource Protection Verification
```bash
# Check WAF associations
aws wafv2 list-web-acls --scope CLOUDFRONT
aws wafv2 list-web-acls --scope REGIONAL

# Verify CloudFront distributions have WAF
aws cloudfront list-distributions --query 'DistributionList.Items[].{Id:Id,WebACLId:WebACLId}'
```

### 3. Compliance Monitoring
```bash
# Check Config rule compliance
aws configservice get-compliance-summary-by-config-rule

# Monitor for 24-48 hours for automatic resource discovery
```

## Rollback Procedures

### 1. Emergency Disable
```hcl
# Disable automatic remediation
enable_automatic_remediation = false

# Switch WAF to monitoring mode
custom_rules = {
  rate_limiting = {
    enabled = true
    action  = "COUNT"  # Change from BLOCK to COUNT
  }
}
```

### 2. Policy Removal
```bash
# Remove specific policies if needed
aws fms delete-policy --policy-id POLICY_ID

# Disable Config rules
aws configservice put-config-rule --config-rule ConfigRuleName=RULE_NAME,State=INACTIVE
```

### 3. Complete Rollback
```bash
# Destroy in reverse order
terraform destroy -target=module.firewall_manager
terraform destroy -target=module.aws_config
terraform destroy
```

## Security Considerations

### 1. Credential Management
- Use Security Admin Account credentials (not Organization Admin)
- Implement least privilege access for security operations
- Enable CloudTrail for audit logging
- Use temporary credentials when possible

### 2. State File Security
```hcl
# Use remote state with encryption
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "security/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

### 3. Variable Security
```bash
# Use environment variables for sensitive data (Security Admin Account)
export TF_VAR_delegated_admin_account_id="123456789012"  # Security Admin Account ID
export TF_VAR_notification_emails="security@company.com"
export AWS_ACCESS_KEY_ID="security-admin-access-key"
export AWS_SECRET_ACCESS_KEY="security-admin-secret-key"

# Avoid storing sensitive data in .tfvars files
```

## Monitoring and Alerting

### 1. CloudWatch Alarms
- Policy compliance drops below threshold
- Config recorder failures
- High WAF block rates
- Unusual traffic patterns

### 2. SNS Notifications
```hcl
# Configure notifications
create_compliance_sns_topic = true
compliance_notification_emails = [
  "security-team@company.com",
  "compliance@company.com"
]
```

### 3. Regular Reviews
- Weekly compliance reports
- Monthly cost optimization reviews
- Quarterly security policy updates
- Annual architecture reviews

## Best Practices Summary

1. **Test in Non-Production First**: Always test in sandbox/development environments
2. **Use Variables**: Avoid hardcoded values in configuration
3. **Gradual Rollout**: Start with limited scope and expand gradually
4. **Monitor Continuously**: Set up proper monitoring and alerting
5. **Document Changes**: Maintain change logs and documentation
6. **Regular Backups**: Backup configurations before changes
7. **Security First**: Follow security best practices throughout
8. **Plan for Rollback**: Always have a rollback plan ready

## Emergency Contacts

Maintain emergency contact information for:
- Security team lead
- Infrastructure team lead
- AWS support (if applicable)
- Compliance team (if applicable)

## Conclusion

Following these safe deployment practices ensures reliable, secure deployment of the Central Security Orchestration solution while minimizing risks to production environments.