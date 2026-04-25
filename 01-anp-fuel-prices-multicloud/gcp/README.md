# GCP — ANP Fuel Prices

Implementação no GCP usando **Cloud Storage + BigQuery External Table**.

## Arquitetura

```
ANP CSV → ingest_anp.py → GCS (raw, partição year/month) → BigQuery (tabela externa) → resultado
```

Componentes provisionados pelo Terraform:
- `google_storage_bucket.raw` — bucket multi-região, uniform bucket-level access, sem acesso público
- `google_bigquery_dataset.anp` — dataset `anp_fuel_prices`
- `google_bigquery_table.weekly_prices_raw` — tabela **externa** com Hive partitioning automático (`year=`, `month=`)

Diferença chave em relação à AWS: aqui a tabela externa **já é criada pelo Terraform** com schema fixo e partição automática, sem precisar de SQL extra de DDL.

## Pré-requisitos

- `gcloud auth application-default login`
- `gcloud config set project <project-id>`
- Terraform >= 1.6
- APIs habilitadas no projeto: `storage.googleapis.com`, `bigquery.googleapis.com`
- Python 3.10+ e `pip install -r ../shared/requirements.txt`

## Passo a passo

```bash
# 1. provisionar a infra
cd gcp/terraform
cp terraform.tfvars.example terraform.tfvars   # ajuste project, bucket_name
terraform init
terraform apply

BUCKET=$(terraform output -raw raw_bucket)
cd ../..

# 2. configurar o ingest
cp shared/config.example.yaml shared/config.yaml
# edite shared/config.yaml — preencha gcp.bucket e gcp.project

# 3. baixar e subir o CSV semanal da ANP
python shared/ingest_anp.py \
    --url "https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/...csv" \
    --target gcp

# 4. rodar as queries (substitua __PROJECT__ pelo seu project id)
sed "s/__PROJECT__/$(gcloud config get project)/g" gcp/sql/02_analytics.sql \
    | bq query --use_legacy_sql=false
```

Ou cole as queries no console do BigQuery — substituindo `__PROJECT__` pelo seu project id.

## Custos esperados

- **GCS:** alguns MB → centavos/mês
- **BigQuery:** primeiro 1 TB de query/mês = grátis. Tabela externa cobra pelo dado escaneado. Aqui são poucos MB → **R$ 0**
- **Storage de tabela externa:** $0 (os dados ficam no GCS, não copiados para o BQ)

Total esperado: < **US$ 0,05/mês**.

## Cleanup

```bash
cd gcp/terraform
terraform destroy
```
