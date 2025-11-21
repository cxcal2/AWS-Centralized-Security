# Outputs for Central Firewall Manager Orchestrator

# Service Status
output "services_enabled" {
  description = "Summary of enabled services"
  value = {
    aws_config       = var.enable_aws_config
    firewall_manager = var.enable_firewall_manager
  }
}

# Management Account Deployment
output "firewall_manager_admin_account" {
  description = "Firewall Manager administrator account ID"
  value       = var.delegated_admin_account_id != "" ? var.delegated_admin_account_id : data.aws_caller_identity.current.account_id
}

output "delegated_admin_setup" {
  description = "Delegated administrator setup information"
  value = var.enable_delegated_admin_setup ? {
    enabled          = true
    admin_account_id = var.delegated_admin_account_id != "" ? var.delegated_admin_account_id : data.aws_caller_identity.current.account_id
    config_delegated = true
    fms_delegated    = true
    deployment_type  = "delegated_admin"
    } : {
    enabled         = false
    deployment_type = "management_account"
  }
}

# AWS Config Outputs
output "config_bucket_name" {
  description = "Name of the Config delivery S3 bucket"
  value       = var.enable_aws_config ? module.aws_config[0].config_bucket_name : null
}

output "target_accounts" {
  description = "List of target accounts with security policies applied"
  value       = var.enable_aws_config ? module.aws_config[0].target_accounts : var.manual_target_accounts
}

output "excluded_accounts" {
  description = "List of excluded accounts (Databricks, etc.)"
  value       = var.enable_aws_config ? module.aws_config[0].excluded_accounts : var.manual_excluded_accounts
}

output "config_aggregator_name" {
  description = "Name of the Config aggregator"
  value       = var.enable_aws_config ? module.aws_config[0].config_aggregator_name : null
}

# WAF Configuration Outputs (now managed by Firewall Manager)
output "waf_configuration_summary" {
  description = "Summary of WAF configuration managed by Firewall Manager"
  value       = var.enable_firewall_manager ? module.firewall_manager[0].waf_configuration_summary : null
}



# Firewall Manager Outputs
output "firewall_manager_policies" {
  description = "List of enabled Firewall Manager policies"
  value       = var.enable_firewall_manager ? module.firewall_manager[0].enabled_policies : []
}

output "policy_summary" {
  description = "Summary of Firewall Manager policy configuration"
  value       = var.enable_firewall_manager ? module.firewall_manager[0].policy_summary : null
}

output "compliance_monitoring" {
  description = "Compliance monitoring configuration"
  value       = var.enable_firewall_manager ? module.firewall_manager[0].compliance_monitoring : null
}

# Dashboard and Monitoring Outputs
output "config_dashboard_name" {
  description = "Name of the Config monitoring dashboard"
  value       = var.enable_aws_config ? module.aws_config[0].dashboard_name : null
}

output "firewall_manager_dashboard_name" {
  description = "Name of the Firewall Manager dashboard"
  value       = var.enable_firewall_manager ? module.firewall_manager[0].dashboard_name : null
}

output "orchestration_dashboard_name" {
  description = "Name of the orchestration overview dashboard"
  value       = var.enable_orchestration_monitoring ? aws_cloudwatch_dashboard.orchestration_overview[0].dashboard_name : null
}

# Cost Optimization Outputs
output "cost_savings_summary" {
  description = "Estimated cost savings from the orchestration"
  value = {
    organization_name       = var.organization_name
    config_savings          = var.enable_aws_config ? module.aws_config[0].cost_savings_summary : null
    firewall_manager_costs  = var.enable_firewall_manager ? module.firewall_manager[0].estimated_monthly_cost : null
    target_accounts_count   = length(var.enable_aws_config ? module.aws_config[0].target_accounts : var.manual_target_accounts)
    excluded_accounts_count = length(var.enable_aws_config ? module.aws_config[0].excluded_accounts : var.manual_excluded_accounts)

    # Cost comparison
    traditional_approach_monthly = (length(var.enable_aws_config ? module.aws_config[0].target_accounts : var.manual_target_accounts) * 500) + (length(var.enable_aws_config ? module.aws_config[0].target_accounts : var.manual_target_accounts) * 200)
    centralized_approach_monthly = 100 + (var.enable_firewall_manager ? 200 : 0)
    estimated_monthly_savings    = (length(var.enable_aws_config ? module.aws_config[0].target_accounts : var.manual_target_accounts) * 700) - 300
  }
}

# Notification Outputs
output "compliance_sns_topic_arn" {
  description = "ARN of the compliance notifications SNS topic"
  value       = var.enable_firewall_manager ? module.firewall_manager[0].compliance_sns_topic_arn : null
}

output "orchestration_sns_topic_arn" {
  description = "ARN of the orchestration alerts SNS topic"
  value       = var.create_orchestration_sns_topic ? aws_sns_topic.orchestration_alerts[0].arn : null
}

# Integration Outputs for External Use
output "integration_summary" {
  description = "Summary for integration with other systems"
  value = {
    organization_name   = var.organization_name
    deployment_region   = data.aws_region.current.name
    security_account_id = data.aws_caller_identity.current.account_id

    services = {
      config_enabled           = var.enable_aws_config
      firewall_manager_enabled = var.enable_firewall_manager
    }

    protection_coverage = {
      cloudfront_protected  = var.enable_cloudfront_waf_policy
      alb_protected         = var.enable_alb_waf_policy
      api_gateway_protected = var.enable_api_gateway_waf_policy
    }

    monitoring = {
      dashboards_enabled       = var.enable_orchestration_monitoring
      compliance_alarms        = var.enable_compliance_alarms
      notifications_configured = var.create_compliance_sns_topic || var.create_orchestration_sns_topic
    }
  }
}

# Deployment Validation
output "deployment_status" {
  description = "Status of the deployment for validation"
  value = {
    timestamp    = timestamp()
    organization = var.organization_name
    services_deployed = compact([
      var.enable_aws_config ? "AWS Config" : "",
      var.enable_firewall_manager ? "Firewall Manager (with WAF)" : ""
    ])
    ready_for_protection = var.enable_aws_config && var.enable_firewall_manager
    architecture         = "Simplified 2-module design following AWS best practices"
  }
}