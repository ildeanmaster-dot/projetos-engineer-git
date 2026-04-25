# Projeto 02 — ANP Fuel Prices no GCP

> Pipeline batch serverless: ingere o CSV mensal de preços de combustíveis da ANP, armazena no GCS particionado por ano/mês e disponibiliza via BigQuery External Table. **Custo previsto: US$ 0/mês** (cabe no free tier de 1 TB/mês).

## Arquitetura

```
gov.br/anp (CSV UTF-8)
        │  HTTPS GET
        ▼
shared/ingest_anp.py  --target gcp
        │  google-cloud-storage upload_from_filename
        ▼
GCS: gs://anp-fuel-prices-ildean26/raw/anp/year=YYYY/month=MM/<arquivo>.csv
        │  Hive partitioning automático
        ▼
BigQuery External Table: anp_fuel_prices.weekly_prices_raw
        │  schema fixo declarado no Terraform
        ▼
Resultados (e.g. preço médio gasolina/UF)
```

## Componentes provisionados pelo Terraform

| Recurso                       | Nome                          | Boas práticas aplicadas |
|-------------------------------|-------------------------------|--------------------------|
| `google_storage_bucket`       | `anp-fuel-prices-ildean26`    | uniform bucket-level access, public access enforced OFF |
| `google_bigquery_dataset`     | `anp_fuel_prices`             | location US (multi-região, free tier) |
| `google_bigquery_table`       | `weekly_prices_raw`           | external table — não copia dado, lê direto do GCS |
| Hive partitioning             | mode = AUTO                   | descobre `year=` e `month=` automaticamente |
| Labels                        | project/owner/env/managed_by  | rastreabilidade e billing por projeto |

> **Diferença para AWS:** aqui a tabela externa **já é criada pelo Terraform** com schema fixo. Não precisa rodar SQL DDL extra como no Athena.

## Pré-requisitos

- `gcloud auth application-default login`
- `gcloud config set project <project-id>`
- APIs habilitadas: `storage.googleapis.com`, `bigquery.googleapis.com`
  ```bash
  gcloud services enable storage.googleapis.com bigquery.googleapis.com
  ```
- Terraform >= 1.6
- Python 3.10+ e `.venv` na raiz com `pip install google-cloud-storage`

## Passo a passo

```bash
# (1) provisionar a infra
cd 02-anp-fuel-prices-gcp/terraform
cp terraform.tfvars.example terraform.tfvars   # ajuste project, bucket_name
terraform init
terraform apply

BUCKET=$(terraform output -raw raw_bucket)
TABLE=$(terraform output -raw bq_external_table)
echo "bucket=$BUCKET  table=$TABLE"
cd ../..

# (2) configurar o ingest
cp shared/config.example.yaml shared/config.yaml
# edite shared/config.yaml: gcp.bucket = $BUCKET, gcp.project

# (3) baixar e subir o CSV
.venv/Scripts/python.exe shared/ingest_anp.py \
    --url "https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/shpc/dsan/2026/03-dados-abertos-precos-gasolina-etanol.csv" \
    --target gcp \
    --reference-date 2026-03-01

# (4) rodar as queries no BigQuery (substitua __PROJECT__ pelo seu project id)
PROJECT=$(gcloud config get project)
sed "s/__PROJECT__/$PROJECT/g" 02-anp-fuel-prices-gcp/sql/02_analytics.sql \
    | bq query --use_legacy_sql=false
```

Ou cole as 3 queries no console do BigQuery (https://console.cloud.google.com/bigquery), substituindo `__PROJECT__`.

## Custos esperados

- **GCS storage:** ~10 MB → ~US$ 0,000 13/mês
- **BigQuery query:** primeiro **1 TB/mês = grátis**. Tabela externa cobra pelo dado escaneado. Aqui são MB → fica no free tier indefinidamente.
- **Storage de tabela externa:** US$ 0 (dados ficam no GCS, não copiados para BQ)

**Total estimado: US$ 0/mês.**

## Cleanup

```bash
cd 02-anp-fuel-prices-gcp/terraform
terraform destroy
```

## Posts relacionados

- 📝 Rascunho do post LinkedIn de quarta → [docs/linkedin-post.md](./docs/linkedin-post.md)
- 🎨 Diagrama de arquitetura → [docs/architecture.md](./docs/architecture.md)
