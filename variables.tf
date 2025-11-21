# Variables for Central Firewall Manager Orchestrator

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "organization_name" {
  description = "Name of the organization (used in resource naming)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.organization_name))
    error_message = "Organization name must contain only alphanumeric characters and hyphens."
  }
}

# FMS Admin Account Configuration (Management Account Deployment)
variable "manage_fms_admin_account" {
  description = "Whether to set current account as FMS admin account (set to false if already exists)"
  type        = bool
  default     = true
}

variable "check_existing_fms_admin" {
  description = "Whether to check for existing FMS admin account before creating new ones"
  type        = bool
  default     = true
}

variable "deploy_to_security_account" {
  description = "Whether to deploy all security resources to the security account instead of management account"
  type        = bool
  default     = false
}

# Optional Delegated Administrator Configuration (Security Team Requirements)
variable "enable_delegated_admin_setup" {
  description = "Enable delegated administrator setup for security account separation (optional)"
  type        = bool
  default     = false
}

variable "delegated_admin_account_id" {
  description = "Account ID to designate as delegated administrator (leave empty to use current account)"
  type        = string
  default     = ""

  validation {
    condition     = var.delegated_admin_account_id == "" || can(regex("^[0-9]{12}$", var.delegated_admin_account_id))
    error_message = "Account ID must be empty or a 12-digit number."
  }
}

variable "create_fms_admin_account" {
  description = "Whether to create FMS admin account designation (set to false if account is already FMS admin)"
  type        = bool
  default     = false
}

variable "cleanup_existing_config" {
  description = "Whether to automatically cleanup existing Config resources that would conflict (recorders, channels, aggregators)"
  type        = bool
  default     = true
}

variable "use_existing_config_resources" {
  description = "Whether to use existing Config delivery channel and recorder instead of creating new ones"
  type        = bool
  default     = false
}

variable "existing_config_bucket_name" {
  description = "Name of existing Config S3 bucket to use when use_existing_config_resources is true"
  type        = string
  default     = ""
}

# Service Enablement (Count-based)
variable "enable_aws_config" {
  description = "Enable AWS Config service (required for resource discovery)"
  type        = bool
  default     = true
}

variable "enable_firewall_manager" {
  description = "Enable Firewall Manager service (creates and manages WAF policies)"
  type        = bool
  default     = true
}



# AWS Config Configuration
variable "config_bucket_name" {
  description = "Name of the S3 bucket for Config delivery"
  type        = string
  default     = ""

  validation {
    condition     = var.config_bucket_name == "" || can(regex("^[a-z0-9.-]+$", var.config_bucket_name))
    error_message = "S3 bucket name must be lowercase alphanumeric with dots and hyphens only."
  }
}

variable "force_destroy_bucket" {
  description = "Allow Terraform to destroy the S3 bucket even if it contains objects (enables lifecycle rules for cleanup)"
  type        = bool
  default     = false # Set to false for production safety
}

variable "databricks_account_patterns" {
  description = "Account name patterns to identify Databricks accounts for exclusion"
  type        = list(string)
  default = [
    "databricks",
    "spark",
    "ml",
    "analytics",
    "data-platform"
  ]
}

variable "additional_excluded_accounts" {
  description = "Additional account IDs to exclude from Config recording"
  type        = list(string)
  default     = []
}

variable "use_account_tags" {
  description = "Whether to use account tags for exclusion identification"
  type        = bool
  default     = false
}

variable "excluded_account_tags" {
  description = "Account tag values that indicate accounts to exclude from Config"
  type        = list(string)
  default = [
    "databricks",
    "analytics",
    "ml-platform"
  ]
}

# OU-based targeting configuration
variable "enable_ou_targeting" {
  description = "Enable Organizational Unit (OU) based targeting instead of account-based targeting"
  type        = bool
  default     = false
}

variable "target_organizational_units" {
  description = "List of Organizational Unit IDs to target for policy deployment"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for ou in var.target_organizational_units : can(regex("^(ou-[0-9a-z-]{10,32}|r-[0-9a-z]{4,32})$", ou))
    ])
    error_message = "OU IDs must be in format 'ou-xxxxxxxxxx' or 'r-xxxx' for root."
  }
}

variable "excluded_organizational_units" {
  description = "List of Organizational Unit IDs to exclude from policy deployment"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for ou in var.excluded_organizational_units : can(regex("^(ou-[0-9a-z-]{10,32}|r-[0-9a-z]{4,32})$", ou))
    ])
    error_message = "OU IDs must be in format 'ou-xxxxxxxxxx' or 'r-xxxx' for root."
  }
}

variable "ou_target_accounts" {
  description = "List of account IDs to target when using OU-based targeting (manual specification)"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for account in var.ou_target_accounts : can(regex("^[0-9]{12}$", account))
    ])
    error_message = "Account IDs must be 12-digit numbers."
  }
}

variable "firewall_manager_resource_types" {
  description = "List of AWS resource types required by Firewall Manager"
  type        = list(string)
  default = [
    "AWS::CloudFront::Distribution",
    "AWS::ElasticLoadBalancingV2::LoadBalancer",
    "AWS::ApiGateway::Stage",
    "AWS::EC2::SecurityGroup"
  ]
}

variable "include_global_resources" {
  description = "Whether to include global resources in Config recording"
  type        = bool
  default     = true
}

variable "aggregate_all_regions" {
  description = "Whether to aggregate Config data from all regions"
  type        = bool
  default     = true
}

# Firewall Manager Policy Configuration
variable "enable_cloudfront_waf_policy" {
  description = "Enable Firewall Manager policy for CloudFront distributions"
  type        = bool
  default     = true
}

variable "enable_alb_waf_policy" {
  description = "Enable Firewall Manager policy for Application Load Balancers"
  type        = bool
  default     = true
}

variable "aws_managed_rules" {
  description = "Configuration for AWS Managed Rules"
  type = object({
    common_rule_set    = optional(bool, true)
    known_bad_inputs   = optional(bool, true)
    ip_reputation      = optional(bool, true)
    sql_injection      = optional(bool, false)
    linux_rule_set     = optional(bool, false)
    windows_rule_set   = optional(bool, false)
    php_rule_set       = optional(bool, false)
    wordpress_rule_set = optional(bool, false)
  })
  default = {
    common_rule_set    = true
    known_bad_inputs   = true
    ip_reputation      = true
    sql_injection      = false
    linux_rule_set     = false
    windows_rule_set   = false
    php_rule_set       = false
    wordpress_rule_set = false
  }
}

variable "common_rule_set_exclusions" {
  description = "List of rules to exclude from Common Rule Set"
  type        = list(string)
  default     = []
}

variable "custom_rules" {
  description = "Configuration for custom WAF rules"
  type = object({
    rate_limiting = optional(object({
      enabled   = optional(bool, false)
      threshold = optional(number, 2000)
      action    = optional(string, "BLOCK")
      }), {
      enabled   = false
      threshold = 2000
      action    = "BLOCK"
    })

    geo_blocking = optional(object({
      enabled   = optional(bool, false)
      countries = optional(list(string), [])
      action    = optional(string, "BLOCK")
      }), {
      enabled   = false
      countries = []
      action    = "BLOCK"
    })

    ip_whitelist = optional(object({
      enabled = optional(bool, false)
      ips     = optional(list(string), [])
      }), {
      enabled = false
      ips     = []
    })

    custom_patterns = optional(object({
      enabled = optional(bool, false)
      patterns = optional(list(object({
        name    = string
        pattern = string
        action  = string
      })), [])
      }), {
      enabled  = false
      patterns = []
    })
  })
  default = {
    rate_limiting = {
      enabled   = false
      threshold = 2000
      action    = "BLOCK"
    }
    geo_blocking = {
      enabled   = false
      countries = []
      action    = "BLOCK"
    }
    ip_whitelist = {
      enabled = false
      ips     = []
    }
    custom_patterns = {
      enabled  = false
      patterns = []
    }
  }
}



variable "enable_api_gateway_waf_policy" {
  description = "Enable Firewall Manager policy for API Gateway"
  type        = bool
  default     = false
}



variable "enable_network_firewall_policy" {
  description = "Enable Network Firewall policy"
  type        = bool
  default     = false
}

variable "network_firewall_stateless_rules" {
  description = "Network Firewall stateless rule group references"
  type = list(object({
    resourceArn = string
    priority    = number
  }))
  default = []
}

variable "network_firewall_stateful_rules" {
  description = "Network Firewall stateful rule group references"
  type = list(object({
    resourceArn = string
  }))
  default = []
}

variable "network_firewall_log_group" {
  description = "CloudWatch log group for Network Firewall logs"
  type        = string
  default     = ""
}

variable "override_customer_waf_association" {
  description = "Override existing customer WAF associations"
  type        = bool
  default     = false
}

variable "enable_automatic_remediation" {
  description = "Enable automatic remediation for non-compliant resources"
  type        = bool
  default     = true
}



# Manual Account Targeting (when Config is disabled)
variable "manual_target_accounts" {
  description = "Manual list of target accounts (used when Config is disabled)"
  type        = list(string)
  default     = []
}

variable "manual_excluded_accounts" {
  description = "Manual list of excluded accounts (used when Config is disabled)"
  type        = list(string)
  default     = []
}

# Monitoring Configuration
variable "enable_config_monitoring" {
  description = "Enable Config monitoring dashboard"
  type        = bool
  default     = true
}

variable "enable_conformance_pack" {
  description = "Enable Config conformance pack"
  type        = bool
  default     = true
}

variable "enable_config_logging" {
  description = "Enable Config logging to CloudWatch"
  type        = bool
  default     = false
}

variable "enable_waf_logging" {
  description = "Enable WAF request logging"
  type        = bool
  default     = true
}

variable "enable_firewall_manager_monitoring" {
  description = "Enable Firewall Manager monitoring dashboard"
  type        = bool
  default     = true
}

variable "enable_orchestration_monitoring" {
  description = "Enable orchestration overview dashboard"
  type        = bool
  default     = true
}

variable "enable_compliance_alarms" {
  description = "Enable CloudWatch alarms for policy compliance"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "redacted_fields" {
  description = "List of header fields to redact in WAF logs"
  type        = list(string)
  default = [
    "authorization",
    "cookie",
    "x-api-key"
  ]
}

# Notification Configuration
variable "create_compliance_sns_topic" {
  description = "Create SNS topic for compliance notifications"
  type        = bool
  default     = false
}

variable "compliance_notification_emails" {
  description = "List of email addresses for compliance notifications"
  type        = list(string)
  default     = []
}

variable "create_orchestration_sns_topic" {
  description = "Create SNS topic for orchestration alerts"
  type        = bool
  default     = false
}

variable "orchestration_notification_emails" {
  description = "List of email addresses for orchestration notifications"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Service   = "CentralFirewallOrchestration"
    ManagedBy = "Terraform"
  }
}
# Resource-specific targeting variables
variable "cloudfront_excluded_accounts" {
  description = "Accounts to exclude from CloudFront WAF policy"
  type        = list(string)
  default     = []
}

variable "alb_excluded_accounts" {
  description = "Accounts to exclude from ALB WAF policy"
  type        = list(string)
  default     = []
}

variable "cloudfront_resource_tags" {
  description = "Tags to target specific CloudFront resources"
  type        = map(string)
  default     = {}
}

variable "alb_resource_tags" {
  description = "Tags to target specific ALB resources"
  type        = map(string)
  default     = {}
}

variable "exclude_existing_waf_resources" {
  description = "Exclude resources that already have WAF associations"
  type        = bool
  default     = true
}
# Custom WAF Policies Configuration
variable "custom_waf_policies" {
  description = "List of custom WAF policies for specific accounts/resources"
  type = list(object({
    name             = string
    resource_type    = string
    target_accounts  = list(string)
    resource_tags    = optional(map(string), {})
    exclude_accounts = optional(list(string), [])

    aws_managed_rules = optional(object({
      common_rule_set    = optional(bool, true)
      known_bad_inputs   = optional(bool, true)
      ip_reputation      = optional(bool, true)
      sql_injection      = optional(bool, false)
      linux_rule_set     = optional(bool, false)
      windows_rule_set   = optional(bool, false)
      php_rule_set       = optional(bool, false)
      wordpress_rule_set = optional(bool, false)
    }), {})

    override_customer_waf_association = optional(bool, false)
    enable_automatic_remediation      = optional(bool, true)
  }))
  default = []
}

# OWASP LLM Protection Configuration
variable "enable_owasp_llm_rules" {
  description = "Enable OWASP LLM Top 10 protection rule groups for custom policies"
  type        = bool
  default     = false
}

variable "llm_rate_limit" {
  description = "Rate limit for LLM API requests (requests per 5 minutes per IP)"
  type        = number
  default     = 10000
}

variable "llm_max_payload_size" {
  description = "Maximum payload size for LLM requests in bytes (default 100MB)"
  type        = number
  default     = 104857600
}
