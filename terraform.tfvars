# Production Central Security Orchestration Configuration
# Configure these values for your organization

# AWS Configuration
aws_region = "us-east-1"

# Organization Configuration
organization_name    = "NS"
config_bucket_name   = "awsns-org-security-config-2024"
force_destroy_bucket = false # Set to false for production

# Security Account Configuration
delegated_admin_account_id    = "353699332254" # Security Account ID (delegated admin setup completed manually)
create_fms_admin_account      = false          # Set to false if account is already FMS admin
cleanup_existing_config       = false
use_existing_config_resources = true
existing_config_bucket_name   = "config-bucket-073306316178"
deploy_to_security_account    = true

# Service Enablement
enable_aws_config       = true
enable_firewall_manager = true

# Account Targeting - Choose ONE approach:

# Option 1: Manual Account targeting (for specific accounts)
# manual_target_accounts = [
#   "503532613196", # AWS Sandbox Account
# ]

# Option 2: OU-based targeting (RECOMMENDED)
enable_ou_targeting = true
target_organizational_units = [
  "ou-cc64-4cfk9zj2", # Sandbox OU
  "ou-cc64-qn9t3lnt", # POC OU
]

# Manual account specification for OU targeting
ou_target_accounts = [
  "503532613196", # AWS Sandbox Account (from Sandbox OU)
]

# Exclude specific OUs if needed (e.g., Databricks, Analytics OUs)
excluded_organizational_units = [
  # "ou-cc64-xxxxx",  # Add any OUs to exclude
]

# Account-based exclusions (still works with OU targeting)
databricks_account_patterns = [
  "databricks",
  "spark",
  "ml",
  "analytics",
]
additional_excluded_accounts = []

# Firewall Manager Configuration
enable_cloudfront_waf_policy = true
enable_alb_waf_policy        = true

# AWS Managed Rules - Production Settings
aws_managed_rules = {
  common_rule_set    = true  # OWASP Top 10 - Required
  known_bad_inputs   = true  # Malicious patterns - Required
  ip_reputation      = true  # Bad IP blocking - Required
  sql_injection      = true  # Enable for database apps
  linux_rule_set     = true  # Enable for Linux apps
  windows_rule_set   = false # Enable for Windows apps
  php_rule_set       = false # Enable for PHP apps
  wordpress_rule_set = false # Enable for WordPress sites
}

# Custom Rules - Production Settings
custom_rules = {
  rate_limiting = {
    enabled   = true
    threshold = 2000 # requests per 5 minutes per IP
    action    = "BLOCK"
  }

  geo_blocking = {
    enabled   = false # Enable if needed
    countries = []    # Add country codes like ["CN", "RU"]
    action    = "BLOCK"
  }

  ip_whitelist = {
    enabled = false # Enable if needed
    ips     = []    # Add trusted CIDR blocks
  }
}

# Policy Configuration
enable_automatic_remediation      = true
override_customer_waf_association = false

# Monitoring Configuration
enable_orchestration_monitoring = true
enable_compliance_alarms        = true
enable_waf_logging              = true
log_retention_days              = 90

# Config Rules Configuration
enable_conformance_pack = true # Enable Config compliance rules - delegated admin now properly configured

# Notification Configuration
create_compliance_sns_topic = true
compliance_notification_emails = [
  "IT_Security_Endpoints@nscorp.com"
]

# ============================================================================
# CUSTOM POLICIES - OWASP LLM Protection for Account 535563617402
# ============================================================================

# Enable OWASP LLM rule groups
enable_owasp_llm_rules = true
llm_rate_limit         = 10000     # 10,000 requests per 5 minutes per IP
llm_max_payload_size   = 104857600 # 100MB

# Custom WAF Policies for OWASP LLM Bedrock Protection
# Each ALB needs its own policy with unique tags
# These policies target ONLY account 535563617402

custom_waf_policies = [
  # Dev ALB 1 - nsiq-dev-owasp-llm-bedrock-protection
  {
    name            = "dev-alb1-owasp-llm-bedrock-protection"
    resource_type   = "AWS::ElasticLoadBalancingV2::LoadBalancer"
    target_accounts = ["535563617402"]
    resource_tags = {
      Environment = "dev"
      Protection  = "llm-owasp"
      Application = "bedrock-api-1"
      PolicyId    = "dev-alb1"
    }
    enable_owasp_llm_protection = true
    aws_managed_rules = {
      common_rule_set    = false
      known_bad_inputs   = true
      ip_reputation      = true
      sql_injection      = false
      linux_rule_set     = false
      windows_rule_set   = false
      php_rule_set       = false
      wordpress_rule_set = false
    }
    override_customer_waf_association = false
    enable_automatic_remediation      = true
  },

  # Dev ALB 2 - Second dev ALB with different application
  {
    name            = "dev-alb2-owasp-llm-bedrock-protection"
    resource_type   = "AWS::ElasticLoadBalancingV2::LoadBalancer"
    target_accounts = ["535563617402"]
    resource_tags = {
      Environment = "dev"
      Protection  = "llm-owasp"
      Application = "bedrock-api-2"
      PolicyId    = "dev-alb2"
    }
    enable_owasp_llm_protection = true
    aws_managed_rules = {
      common_rule_set    = false
      known_bad_inputs   = true
      ip_reputation      = true
      sql_injection      = false
      linux_rule_set     = false
      windows_rule_set   = false
      php_rule_set       = false
      wordpress_rule_set = false
    }
    override_customer_waf_association = false
    enable_automatic_remediation      = true
  },

  # Dev ALB 3 - Third dev ALB with different application
  {
    name            = "dev-alb3-owasp-llm-bedrock-protection"
    resource_type   = "AWS::ElasticLoadBalancingV2::LoadBalancer"
    target_accounts = ["535563617402"]
    resource_tags = {
      Environment = "dev"
      Protection  = "llm-owasp"
      Application = "bedrock-api-3"
      PolicyId    = "dev-alb3"
    }
    enable_owasp_llm_protection = true
    aws_managed_rules = {
      common_rule_set    = false
      known_bad_inputs   = true
      ip_reputation      = true
      sql_injection      = false
      linux_rule_set     = false
      windows_rule_set   = false
      php_rule_set       = false
      wordpress_rule_set = false
    }
    override_customer_waf_association = false
    enable_automatic_remediation      = true
  },

  #   # Production Account - ns-nsiq-prod-owasp-llm-bedrock-protection
  #   # Account: 463554031494 (different from dev account)
  #   {
  #     name            = "prod-owasp-llm-bedrock-protection"
  #     resource_type   = "AWS::ElasticLoadBalancingV2::LoadBalancer"
  #     target_accounts = ["463554031494"]
  #     resource_tags = {
  #       Environment = "production"
  #       Protection  = "llm-owasp"
  #     }
  #     enable_owasp_llm_protection = true
  #     aws_managed_rules = {
  #       common_rule_set    = false
  #       known_bad_inputs   = true
  #       ip_reputation      = true
  #       sql_injection      = true
  #       linux_rule_set     = true
  #       windows_rule_set   = false
  #       php_rule_set       = false
  #       wordpress_rule_set = false
  #     }
  #     override_customer_waf_association = false
  #     enable_automatic_remediation      = true
  #   }
]

# Tags
tags = {
  Environment = "Production"
  Team        = "SecurityTeam"
  Purpose     = "CentralSecurityOrchestration"
  ManagedBy   = "Terraform"
  Owner       = "SecurityTeam"
}
