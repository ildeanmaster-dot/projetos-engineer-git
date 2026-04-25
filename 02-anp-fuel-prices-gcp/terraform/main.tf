terraform {
  required_version = ">= 1.6"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.40"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

variable "project" {
  type        = string
  description = "GCP project id"
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "location" {
  type        = string
  default     = "US"
  description = "Location multiregião (US/EU) para GCS e BigQuery"
}

variable "bucket_name" {
  type        = string
  description = "Nome global do bucket GCS"
}

variable "bq_dataset" {
  type    = string
  default = "anp_fuel_prices"
}

locals {
  common_labels = {
    project    = "anp-fuel-prices"
    owner      = "ildean"
    env        = "portfolio"
    managed_by = "terraform"
    repo       = "projetos-engineer-git"
  }
}

resource "google_storage_bucket" "raw" {
  name                        = var.bucket_name
  location                    = var.location
  uniform_bucket_level_access = true
  force_destroy               = true
  public_access_prevention    = "enforced"

  labels = local.common_labels
}

resource "google_bigquery_dataset" "anp" {
  dataset_id = var.bq_dataset
  location   = var.location
  labels     = local.common_labels
}

# Tabela externa apontando para os CSVs no GCS, particionada via Hive partitioning
resource "google_bigquery_table" "weekly_prices_raw" {
  dataset_id          = google_bigquery_dataset.anp.dataset_id
  table_id            = "weekly_prices_raw"
  deletion_protection = false

  external_data_configuration {
    autodetect    = false
    source_format = "CSV"
    source_uris   = ["gs://${google_storage_bucket.raw.name}/raw/anp/*"]

    csv_options {
      quote                 = "\""
      skip_leading_rows     = 1
      field_delimiter       = ";"
      allow_quoted_newlines = true
      encoding              = "UTF-8"
    }

    hive_partitioning_options {
      mode              = "AUTO"
      source_uri_prefix = "gs://${google_storage_bucket.raw.name}/raw/anp/"
    }

    schema = jsonencode([
      { name = "regiao_sigla",   type = "STRING" },
      { name = "estado_sigla",   type = "STRING" },
      { name = "municipio",      type = "STRING" },
      { name = "revenda",        type = "STRING" },
      { name = "cnpj_revenda",   type = "STRING" },
      { name = "nome_rua",       type = "STRING" },
      { name = "numero_rua",     type = "STRING" },
      { name = "complemento",    type = "STRING" },
      { name = "bairro",         type = "STRING" },
      { name = "cep",            type = "STRING" },
      { name = "produto",        type = "STRING" },
      { name = "data_coleta",    type = "STRING" },
      { name = "valor_venda",    type = "STRING" },
      { name = "valor_compra",   type = "STRING" },
      { name = "unidade_medida", type = "STRING" },
      { name = "bandeira",       type = "STRING" },
    ])
  }
}

output "raw_bucket" {
  value = google_storage_bucket.raw.name
}

output "bq_dataset" {
  value = google_bigquery_dataset.anp.dataset_id
}

output "bq_external_table" {
  value = "${var.project}.${google_bigquery_dataset.anp.dataset_id}.${google_bigquery_table.weekly_prices_raw.table_id}"
}
