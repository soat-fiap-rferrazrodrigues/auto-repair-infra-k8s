# ── Alertas exigidos: latência, recursos, uptime e falhas de ordens de serviço ──

# 1. API latency (p95)
resource "datadog_monitor" "api_latency" {
  name    = "[${var.environment}] API latency p95 above 1s"
  type    = "metric alert"
  message = <<-EOT
    The 95th percentile latency of ${local.service} is degraded.
    Check APM traces and database performance.
    ${var.alert_channel}
  EOT

  query = "avg(last_10m):p95:trace.express.request.duration{service:${local.service},env:${var.environment}} > 1"

  monitor_thresholds {
    critical = 1
    warning  = 0.5
  }

  tags = local.tags
}

# 2. Error rate on the API
resource "datadog_monitor" "api_error_rate" {
  name    = "[${var.environment}] API error rate above 5%"
  type    = "metric alert"
  message = <<-EOT
    More than 5% of requests to ${local.service} are failing.
    ${var.alert_channel}
  EOT

  query = <<-QUERY
    sum(last_5m):sum:trace.express.request.errors{service:${local.service},env:${var.environment}}.as_count() /
    sum:trace.express.request.hits{service:${local.service},env:${var.environment}}.as_count() > 0.05
  QUERY

  monitor_thresholds {
    critical = 0.05
    warning  = 0.02
  }

  tags = local.tags
}

# 3. Kubernetes CPU consumption vs the HPA target (70%)
resource "datadog_monitor" "pod_cpu" {
  name    = "[${var.environment}] Pod CPU usage sustained above HPA target"
  type    = "metric alert"
  message = <<-EOT
    Pods are sustaining high CPU. Verify whether the HPA is scaling as expected.
    ${var.alert_channel}
  EOT

  query = "avg(last_15m):avg:kubernetes.cpu.usage.total{kube_deployment:auto-repair-api,env:${var.environment}} / avg:kubernetes.cpu.limits{kube_deployment:auto-repair-api,env:${var.environment}} > 0.85"

  monitor_thresholds {
    critical = 0.85
    warning  = 0.7
  }

  tags = local.tags
}

# 4. Kubernetes memory consumption
resource "datadog_monitor" "pod_memory" {
  name    = "[${var.environment}] Pod memory usage above 90% of limit"
  type    = "metric alert"
  message = <<-EOT
    Pods are close to the memory limit and risk being OOMKilled.
    ${var.alert_channel}
  EOT

  query = "avg(last_10m):avg:kubernetes.memory.usage{kube_deployment:auto-repair-api,env:${var.environment}} / avg:kubernetes.memory.limits{kube_deployment:auto-repair-api,env:${var.environment}} > 0.9"

  monitor_thresholds {
    critical = 0.9
    warning  = 0.75
  }

  tags = local.tags
}

# 5. Uptime / healthcheck via Synthetics
resource "datadog_synthetics_test" "uptime" {
  name      = "[${var.environment}] Auto Repair API uptime"
  type      = "api"
  subtype   = "http"
  status    = "live"
  locations = ["aws:sa-east-1", "aws:us-east-1"]
  message   = "Auto Repair API health endpoint is failing. ${var.alert_channel}"

  request_definition {
    method = "GET"
    url    = "${var.api_base_url}/health"
  }

  assertion {
    type     = "statusCode"
    operator = "is"
    target   = "200"
  }

  assertion {
    type     = "responseTime"
    operator = "lessThan"
    target   = "2000"
  }

  options_list {
    tick_every = 60
    retry {
      count    = 2
      interval = 300
    }
  }

  tags = local.tags
}

# 6. Failures while processing service orders (business-critical)
resource "datadog_monitor" "service_order_failures" {
  name    = "[${var.environment}] Failures processing service orders"
  type    = "log alert"
  message = <<-EOT
    Errors were detected while processing service orders (OS).
    Inspect correlated logs using the correlation_id field.
    ${var.alert_channel}
  EOT

  query = "logs(\"service:${local.service} env:${var.environment} status:error (@context:OrdersService OR @context:UpdateOrderStatusUseCase)\").index(\"*\").rollup(\"count\").last(\"10m\") > 5"

  monitor_thresholds {
    critical = 5
    warning  = 1
  }

  tags = local.tags
}

# 7. Authentication Lambda failures
resource "datadog_monitor" "auth_lambda_errors" {
  name    = "[${var.environment}] CPF authentication Lambda errors"
  type    = "metric alert"
  message = <<-EOT
    The CPF authentication function is failing; customers cannot obtain tokens.
    ${var.alert_channel}
  EOT

  query = "sum(last_5m):sum:aws.lambda.errors{functionname:auto-repair-auth-${var.environment}}.as_count() > 3"

  monitor_thresholds {
    critical = 3
    warning  = 1
  }

  tags = local.tags
}

variable "api_base_url" {
  description = "Public base URL used by the uptime synthetic test"
  type        = string
}
