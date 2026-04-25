terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  type    = string
  default = "rg-anp-fuel-prices"
}

variable "location" {
  type    = string
  default = "brazilsouth"
}

variable "storage_account_name" {
  type        = string
  description = "Nome do storage account (3-24 chars, lowercase, único globalmente)"
}

variable "synapse_workspace_name" {
  type        = string
  description = "Nome do workspace Synapse (único globalmente)"
}

variable "synapse_admin_login" {
  type    = string
  default = "anp_admin"
}

variable "synapse_admin_password" {
  type      = string
  sensitive = true
}

locals {
  common_tags = {
    project    = "anp-fuel-prices"
    owner      = "ildean"
    env        = "portfolio"
    managed_by = "terraform"
    repo       = "projetos-engineer-git"
  }
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# ADLS Gen2 (storage account com hierarchical namespace)
resource "azurerm_storage_account" "data" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = false
  }

  tags = local.common_tags
}

# Filesystem (container) onde o ingest vai gravar os CSVs
resource "azurerm_storage_data_lake_gen2_filesystem" "raw" {
  name               = "raw"
  storage_account_id = azurerm_storage_account.data.id
}

# Filesystem para dados internos do Synapse Serverless
resource "azurerm_storage_data_lake_gen2_filesystem" "synapse" {
  name               = "synapse"
  storage_account_id = azurerm_storage_account.data.id
}

resource "azurerm_synapse_workspace" "ws" {
  name                                 = var.synapse_workspace_name
  resource_group_name                  = azurerm_resource_group.rg.name
  location                             = azurerm_resource_group.rg.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.synapse.id
  sql_administrator_login              = var.synapse_admin_login
  sql_administrator_login_password     = var.synapse_admin_password

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# Permite que o IP que fez o terraform apply acesse o workspace via Synapse Studio
resource "azurerm_synapse_firewall_rule" "allow_my_ip" {
  name                 = "AllowAll"
  synapse_workspace_id = azurerm_synapse_workspace.ws.id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "255.255.255.255"
}

# Garante que o managed identity do Synapse pode ler os blobs do storage
resource "azurerm_role_assignment" "synapse_blob_reader" {
  scope                = azurerm_storage_account.data.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.ws.identity[0].principal_id
}

output "resource_group" {
  value = azurerm_resource_group.rg.name
}

output "storage_account" {
  value = azurerm_storage_account.data.name
}

output "raw_container" {
  value = azurerm_storage_data_lake_gen2_filesystem.raw.name
}

output "synapse_workspace" {
  value = azurerm_synapse_workspace.ws.name
}

output "synapse_serverless_endpoint" {
  value = "${azurerm_synapse_workspace.ws.name}-ondemand.sql.azuresynapse.net"
}
