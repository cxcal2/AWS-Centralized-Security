# Policy Override Guide

This guide explains how to override centralized policies at the individual account level.

## 🎯 **Override Methods by Service**

### **1. Firewall Manager WAF Policies (✅ BEST OVERRIDE OPTIONS)**

#### **Method 1: Resource Tag Exclusions**
```hcl
# In target account - Tag resources to exclude from FMS policies
resource "aws_cloudfront_distribution" "custom_app" {
  # ... configuration
  
  tags = {
    FMSExclude = "true"           # Exclude from Firewall Manager
    CustomWAF  = "managed-locally" # Indicate local management
  }
}

# Then update centralized policy to respect tags
resource "aws_fms_policy" "cloudfront_waf_policy" {
  exclude_resource_tags = true  # Enable tag-based exclusions
  
  resource_tags = {
    FMSExclude = "true"  # Resources with this tag will be excluded
  }
}
```

#### **Method 2: Account-Level WAF Rules**
```hcl
# In target account - Create additional WAF rules
resource "aws_wafv2_web_acl" "account_specific_waf" {
  name  = "account-specific-overrides"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # Custom rule that overrides centralized behavior
  rule {
    name     = "CustomRateLimiting"
    priority = 1  # Higher priority than FMS rules

    override_action {
      none {}
    }

    statement {
      rate_based_statement {
        limit              = 5000  # Different from centralized limit
        aggregate_key_type = "IP"
      }
    }

    action {
      block {}
    }
  }
}
```

#### **Method 3: Policy-Level Account Exclusions**
```hcl
# In centralized configuration - Exclude specific accounts
resource "aws_fms_policy" "cloudfront_waf_policy" {
  # Exclude accounts that need custom policies
  exclude_map {
    account = ["123456789012"]  # Account with custom requirements
  }
}
```

### **2. AWS Config Organization Rules (❌ LIMITED OVERRIDE)**

#### **Method 1: Resource Tag Exclusions (Workaround)**
```hcl
# In target account - Tag resources to indicate custom handling
resource "aws_cloudfront_distribution" "custom_app" {
  tags = {
    ConfigExclude = "custom-compliance"
    ComplianceType = "manual-review"
  }
}

# Note: Config organization rules don't natively support tag exclusions
# This is for documentation/tracking purposes
```

#### **Method 2: Account-Level Config Rules (Supplementary)**
```hcl
# In target account - Create additional Config rules
resource "aws_config_config_rule" "custom_cloudfront_rule" {
  name = "custom-cloudfront-waf-check"

  source {
    owner             = "AWS"
    source_identifier = "CLOUDFRONT_ASSOCIATED_WITH_WAF"
  }

  # Custom input parameters that differ from organization rule
  input_parameters = jsonencode({
    requiredWafType = "CUSTOM"  # Different requirement
  })
}
```

## 🛠️ **Implementation Examples**

### **Example 1: Development Account Override**
```hcl
# Scenario: Development account needs relaxed WAF rules

# In centralized terraform.tfvars
excluded_accounts = ["111111111111"]  # Exclude dev account

# In development account (111111111111)
resource "aws_wafv2_web_acl" "dev_waf" {
  name  = "development-waf"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # Relaxed rate limiting for testing
  rule {
    name     = "DevRateLimiting"
    priority = 1

    statement {
      rate_based_statement {
        limit              = 10000  # Higher limit for dev
        aggregate_key_type = "IP"
      }
    }

    action {
      count {}  # Count instead of block for testing
    }
  }
}
```

### **Example 2: High-Traffic Application Override**
```hcl
# Scenario: Production app needs custom WAF configuration

# In target account - Tag the distribution
resource "aws_cloudfront_distribution" "high_traffic_app" {
  tags = {
    FMSExclude = "true"
    WAFType    = "custom-high-performance"
  }
}

# Create custom WAF with optimized rules
resource "aws_wafv2_web_acl" "high_performance_waf" {
  name  = "high-performance-waf"
  scope = "CLOUDFRONT"

  # Custom rules optimized for high traffic
  rule {
    name     = "OptimizedRateLimit"
    priority = 1

    statement {
      rate_based_statement {
        limit              = 50000  # Much higher limit
        aggregate_key_type = "IP"
      }
    }

    action {
      block {}
    }
  }
}
```

## 🔧 **Configuration Updates Needed**

### **1. Update Firewall Manager Variables**
```hcl
# Add to firewall-manager/variables.tf
variable "enable_resource_tag_exclusions" {
  description = "Enable resource tag-based exclusions from FMS policies"
  type        = bool
  default     = true
}

variable "policy_resource_tags" {
  description = "Resource tags that exclude resources from FMS policies"
  type        = map(string)
  default = {
    FMSExclude = "true"
  }
}
```

### **2. Update terraform.tfvars**
```hcl
# Enable tag-based exclusions
enable_resource_tag_exclusions = true

# Define exclusion tags
policy_resource_tags = {
  FMSExclude = "true"
  CustomWAF  = "managed-locally"
}
```

## 📋 **Override Decision Matrix**

| Override Need | Config Rules | Firewall Manager | Recommendation |
|---------------|--------------|------------------|----------------|
| **Exclude Account** | ✅ excluded_accounts | ✅ exclude_map | Use centralized exclusion |
| **Exclude Resources** | ❌ Limited | ✅ Resource tags | Use FMS tag exclusions |
| **Custom Parameters** | ❌ Not supported | ✅ Account-level WAF | Create custom WAF |
| **Additional Rules** | ✅ Local Config rules | ✅ Local WAF rules | Add supplementary rules |
| **Different Thresholds** | ❌ Not supported | ✅ Custom WAF | Override with custom WAF |

## 🎯 **Best Practices**

### **1. Documentation**
- **Tag Resources**: Always tag overridden resources for tracking
- **Document Reasons**: Maintain documentation for why overrides are needed
- **Review Regularly**: Periodically review if overrides are still necessary

### **2. Governance**
- **Approval Process**: Require approval for policy overrides
- **Security Review**: Ensure overrides don't compromise security
- **Compliance Check**: Verify overrides meet compliance requirements

### **3. Monitoring**
- **Override Tracking**: Monitor which resources have overrides
- **Compliance Gaps**: Track compliance status of overridden resources
- **Regular Audits**: Audit override usage and effectiveness

## 🚨 **Important Notes**

1. **Config Organization Rules**: Have very limited override capabilities
2. **Firewall Manager**: Provides better override options through tags and exclusions
3. **Account Exclusions**: Most effective for complete account-level overrides
4. **Resource Tags**: Best method for selective resource overrides
5. **Custom Rules**: Can supplement but not replace organization rules

## 📞 **Support**

For override implementation help:
- Review this guide for appropriate method
- Test overrides in development environment first
- Document all overrides for compliance tracking
- Monitor override effectiveness and security impact