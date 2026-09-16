# Operational + business dashboard required by the challenge.
resource "datadog_dashboard" "operations" {
  title       = "[${var.environment}] Auto Repair Shop - Operations"
  description = "API latency, Kubernetes resources, uptime and service order business metrics"
  layout_type = "ordered"

  # ── API performance ─────────────────────────────────────────────────────────
  widget {
    timeseries_definition {
      title = "API latency (p50 / p95 / p99)"

      request {
        q            = "p50:trace.express.request.duration{service:${local.service},env:${var.environment}}"
        display_type = "line"
      }
      request {
        q            = "p95:trace.express.request.duration{service:${local.service},env:${var.environment}}"
        display_type = "line"
      }
      request {
        q            = "p99:trace.express.request.duration{service:${local.service},env:${var.environment}}"
        display_type = "line"
      }
    }
  }

  widget {
    timeseries_definition {
      title = "Throughput and errors"

      request {
        q            = "sum:trace.express.request.hits{service:${local.service},env:${var.environment}}.as_count()"
        display_type = "bars"
      }
      request {
        q            = "sum:trace.express.request.errors{service:${local.service},env:${var.environment}}.as_count()"
        display_type = "bars"
      }
    }
  }

  # ── Kubernetes resources ────────────────────────────────────────────────────
  widget {
    timeseries_definition {
      title = "Kubernetes CPU and memory usage"

      request {
        q            = "avg:kubernetes.cpu.usage.total{kube_deployment:auto-repair-api,env:${var.environment}}"
        display_type = "area"
      }
      request {
        q            = "avg:kubernetes.memory.usage{kube_deployment:auto-repair-api,env:${var.environment}}"
        display_type = "line"
      }
    }
  }

  widget {
    timeseries_definition {
      title = "HPA: running replicas"

      request {
        q            = "avg:kubernetes.deployment.replicas_available{kube_deployment:auto-repair-api,env:${var.environment}}"
        display_type = "area"
      }
    }
  }

  # ── Uptime ──────────────────────────────────────────────────────────────────
  widget {
    timeseries_definition {
      title = "Uptime and health endpoint response time"

      request {
        q            = "avg:synthetics.http.response.time{check_id:${datadog_synthetics_test.uptime.id}}"
        display_type = "line"
      }
    }
  }

  # ── Business metrics ────────────────────────────────────────────────────────
  widget {
    timeseries_definition {
      title = "Daily volume of service orders created"

      request {
        log_query {
          index = "*"
          compute_query {
            aggregation = "count"
          }
          search_query = "service:${local.service} env:${var.environment} @context:CreateOrderUseCase"
          group_by {
            facet = "@status"
          }
        }
        display_type = "bars"
      }
    }
  }

  widget {
    query_value_definition {
      title = "Average execution time per status (Diagnosis / Execution / Finished)"

      request {
        log_query {
          index = "*"
          compute_query {
            aggregation = "avg"
            facet       = "@duration_minutes"
          }
          search_query = "service:${local.service} env:${var.environment} @context:UpdateOrderStatusUseCase"
        }
      }
    }
  }

  widget {
    timeseries_definition {
      title = "Integration failures (email webhook and authentication)"

      request {
        log_query {
          index = "*"
          compute_query {
            aggregation = "count"
          }
          search_query = "env:${var.environment} status:error (service:${local.service} OR service:auto-repair-auth-lambda)"
        }
        display_type = "bars"
      }
    }
  }
}

output "dashboard_url" {
  description = "Public URL of the operations dashboard"
  value       = datadog_dashboard.operations.url
}
