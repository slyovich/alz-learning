variable "PROJECT" {
  type        = string
  description = "Project name"
}

variable "ENVIRONMENT" {
  type        = string
  description = "The environment (e.g. dev, tst, prd)."
  validation {
    condition     = contains(["dev", "tst", "prd"], lower(var.ENVIRONMENT))
    error_message = "The environment must be one of: dev, tst, prd."
  }
}

variable "REGION_NAME" {
  type        = string
  description = "The Azure region where the resources will be created."
}

variable "REGION_SHORTNAME" {
  type        = string
  description = "The short name of the Azure region where the resources will be created."
}

variable "SUBSCRIPTION_ID" {
  type        = string
  description = "The Azure subscription ID where the resources will be created."
}

variable "ADMINISTRATOR_LOGIN" {
  type        = string
  description = "Administrator (cluster) login name. Must start with a letter; allowed: letters, numbers, - and _."
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_-]{3,30}$", var.ADMINISTRATOR_LOGIN))
    error_message = "ADMINISTRATOR_LOGIN must be 4-31 chars, start with a letter, and contain only letters, numbers, - or _."
  }
}

variable "ADMINISTRATOR_LOGIN_PASSWORD" {
  type        = string
  description = "Administrator login password (sensitive). Prefer injecting from a secure external secret source (e.g., TF Cloud Var, Key Vault data source)."
  nullable    = false
  sensitive   = true

  validation {
    condition     = length(var.ADMINISTRATOR_LOGIN_PASSWORD) >= 12
    error_message = "ADMINISTRATOR_LOGIN_PASSWORD must be at least 12 characters (apply your org complexity policy)."
  }
}