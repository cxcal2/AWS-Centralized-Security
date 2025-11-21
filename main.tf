

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_organizations_organization" "current" {}

locals {
  fms_admin_account_id    = var.delegated_admin_account_id != "" ? var.delegated_admin_account_id : data.aws_caller_identity.current.account_id
  should_create_fms_admin = var.create_fms_admin_account
  is_management_account   = data.aws_organizations_organization.current.master_account_id == data.aws_caller_identity.current.account_id
}




# Delegated Administrator Setup (only if enabled and running from management account)
resource "aws_organizations_delegated_administrator" "config" {
  count = var.enable_delegated_admin_setup && local.is_management_account ? 1 : 0

  account_id        = local.fms_admin_account_id
  service_principal = "config.amazonaws.com"
}

resource "aws_organizations_delegated_administrator" "fms" {
  count = var.enable_delegated_admin_setup && local.is_management_account ? 1 : 0

  account_id        = local.fms_admin_account_id
  service_principal = "fms.amazonaws.com"
}

locals {
  config_bucket_validation = var.enable_aws_config && var.config_bucket_name == "" ? tobool("config_bucket_name is required when enable_aws_config is true") : true
}


module "aws_config" {
  count  = var.enable_aws_config ? 1 : 0
  source = "./aws-config"

  organization_name    = var.organization_name
  config_bucket_name   = var.config_bucket_name
  force_destroy_bucket = var.force_destroy_bucket

  databricks_account_patterns  = var.databricks_account_patterns
  additional_excluded_accounts = var.additional_excluded_accounts
  use_account_tags             = var.use_account_tags
  excluded_account_tags        = var.excluded_account_tags

  enable_ou_targeting           = var.enable_ou_targeting
  target_organizational_units   = var.target_organizational_units
  excluded_organizational_units = var.excluded_organizational_units
  ou_target_accounts            = var.ou_target_accounts

  firewall_manager_resource_types = var.firewall_manager_resource_types
  include_global_resources        = var.include_global_resources
  aggregate_all_regions           = var.aggregate_all_regions

  cleanup_existing_config       = var.cleanup_existing_config
  use_existing_config_resources = var.use_existing_config_resources
  existing_config_bucket_name   = var.existing_config_bucket_name

  enable_monitoring_dashboard = var.enable_config_monitoring
  enable_conformance_pack     = var.enable_conformance_pack
  enable_config_logging       = var.enable_config_logging
  log_retention_days          = var.log_retention_days

  tags = var.tags

  depends_on = [
    aws_organizations_delegated_administrator.config,
    aws_organizations_delegated_administrator.fms
  ]
}




module "firewall_manager" {
  count  = var.enable_firewall_manager ? 1 : 0
  source = "./firewall-manager"

  organization_name = var.organization_name

  target_accounts   = var.enable_aws_config ? module.aws_config[0].target_accounts : var.manual_target_accounts
  excluded_accounts = var.enable_aws_config ? module.aws_config[0].excluded_accounts : var.manual_excluded_accounts

  enable_cloudfront_waf_policy  = var.enable_cloudfront_waf_policy
  enable_alb_waf_policy         = var.enable_alb_waf_policy
  enable_api_gateway_waf_policy = var.enable_api_gateway_waf_policy

  aws_managed_rules          = var.aws_managed_rules
  common_rule_set_exclusions = var.common_rule_set_exclusions

  custom_rules = var.custom_rules

  override_customer_waf_association = var.override_customer_waf_association
  enable_automatic_remediation      = var.enable_automatic_remediation

  enable_waf_logging = var.enable_waf_logging
  log_retention_days = var.log_retention_days

  enable_monitoring_dashboard    = var.enable_firewall_manager_monitoring
  enable_compliance_alarms       = var.enable_compliance_alarms
  create_compliance_sns_topic    = var.create_compliance_sns_topic
  compliance_notification_emails = var.compliance_notification_emails

  cloudfront_excluded_accounts   = var.cloudfront_excluded_accounts
  alb_excluded_accounts          = var.alb_excluded_accounts
  cloudfront_resource_tags       = var.cloudfront_resource_tags
  alb_resource_tags              = var.alb_resource_tags
  exclude_existing_waf_resources = var.exclude_existing_waf_resources
  custom_waf_policies            = var.custom_waf_policies

  # OWASP LLM Protection
  enable_owasp_llm_rules = var.enable_owasp_llm_rules
  llm_rate_limit         = var.llm_rate_limit
  llm_max_payload_size   = var.llm_max_payload_size

  tags = var.tags

  depends_on = [module.aws_config]
}


resource "aws_cloudwatch_dashboard" "orchestration_overview" {
  count          = var.enable_orchestration_monitoring ? 1 : 0
  dashboard_name = "${var.organization_name}-CentralFirewallOrchestration"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 3

        properties = {
          markdown = "# ${var.organization_name} Central Firewall Manager Orchestration\n\n**Services Enabled**: Config: ${var.enable_aws_config ? "[+]" : "[-]"} | Firewall Manager: ${var.enable_firewall_manager ? "[+]" : "[-]"}\n\n**Target Accounts**: ${var.enable_aws_config ? length(module.aws_config[0].target_accounts) : length(var.manual_target_accounts)} | **Excluded Accounts**: ${var.enable_aws_config ? length(module.aws_config[0].excluded_accounts) : length(var.manual_excluded_accounts)}\n\n**Architecture**: Simplified 2-module design following AWS best practices"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 3
        width  = 8
        height = 6

        properties = {
          metrics = var.enable_aws_config ? [
            ["AWS/Config", "NumberOfConfigurationRecorders"],
            ["AWS/Config", "NumberOfDeliveryChannels"]
          ] : []
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Config Service Status"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 3
        width  = 8
        height = 6

        properties = {
          metrics = var.enable_firewall_manager ? [
            ["AWS/WAFV2", "AllowedRequests", "WebACL", "${var.organization_name}-cloudfront-waf"],
            ["AWS/WAFV2", "BlockedRequests", "WebACL", "${var.organization_name}-cloudfront-waf"]
          ] : []
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "WAF Request Metrics (Firewall Manager)"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 3
        width  = 8
        height = 6

        properties = {
          metrics = var.enable_firewall_manager ? [
            ["AWS/FMS", "ComplianceByPolicy", "Policy", "${var.organization_name}-cloudfront-waf-policy"],
            ["AWS/FMS", "ComplianceByPolicy", "Policy", "${var.organization_name}-alb-waf-policy"]
          ] : []
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Firewall Manager Compliance"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      }
    ]
  })
}





resource "aws_sns_topic" "orchestration_alerts" {
  count = var.create_orchestration_sns_topic ? 1 : 0

  name = "${var.organization_name}-central-firewall-orchestration-alerts"

  tags = var.tags
}

resource "aws_sns_topic_subscription" "orchestration_email_alerts" {
  count = var.create_orchestration_sns_topic && length(var.orchestration_notification_emails) > 0 ? length(var.orchestration_notification_emails) : 0

  topic_arn = aws_sns_topic.orchestration_alerts[0].arn
  protocol  = "email"
  endpoint  = var.orchestration_notification_emails[count.index]
}
