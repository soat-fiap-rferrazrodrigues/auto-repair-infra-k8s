terraform {
  required_version = ">= 1.5.0"

  required_providers {
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.39"
    }
  }

  backend "s3" {
    bucket = "auto-repair-terraform-state"
    key    = "monitoring/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "datadog" {
  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
  api_url = var.datadog_api_url
}

variable "datadog_api_key" {
  type      = string
  sensitive = true
}

variable "datadog_app_key" {
  type      = string
  sensitive = true
}

variable "datadog_api_url" {
  type    = string
  default = "https://api.datadoghq.com/"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "alert_channel" {
  description = "Notification target, e.g. @slack-oficina-alertas or @email"
  type        = string
  default     = "@slack-auto-repair-alerts"
}

locals {
  service = "auto-repair-shop-api"
  tags    = ["project:auto-repair-shop", "env:${var.environment}"]
}
