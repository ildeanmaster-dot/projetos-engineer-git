# AWS — ANP Fuel Prices

Implementação na AWS usando **S3 + Glue Data Catalog + Athena**.

## Arquitetura

```
ANP CSV → ingest_anp.py → S3 (raw, partição year/month) → Athena (schema-on-read via Glue) → resultado
```

Componentes provisionados pelo Terraform:
- `aws_s3_bucket.raw` — bucket de dados crus (versionamento off, encryption SSE-S3, sem acesso público)
- `aws_s3_bucket.athena_results` — bucket separado para resultados de query
- `aws_glue_catalog_database.anp` — database lógico no Glue
- `aws_athena_workgroup.anp` — workgroup com `output_location` configurado

A tabela externa usa **partition projection** (sem precisar de `MSCK REPAIR TABLE` ou Crawler) — basta subir o arquivo no caminho `raw/anp/year=YYYY/month=MM/` e a partição é descoberta automaticamente.

## Pré-requisitos

- AWS CLI configurado (`aws configure`) com permissões de S3, Glue e Athena
- Terraform >= 1.6
- Python 3.10+ e `pip install -r ../shared/requirements.txt`

## Passo a passo

```bash
# 1. provisionar a infra
cd aws/terraform
cp terraform.tfvars.example terraform.tfvars   # ajuste bucket_name
terraform init
terraform apply

# anote o output: raw_bucket
BUCKET=$(terraform output -raw raw_bucket)
cd ../..

# 2. configurar o ingest
cp shared/config.example.yaml shared/config.yaml
# edite shared/config.yaml — preencha aws.bucket com $BUCKET

# 3. baixar e subir o CSV semanal da ANP
python shared/ingest_anp.py \
    --url "https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/...csv" \
    --target aws

# 4. criar a tabela externa no Athena (substitua __BUCKET_NAME__)
sed "s/__BUCKET_NAME__/$BUCKET/g" aws/sql/01_create_external_table.sql \
    | aws athena start-query-execution \
        --query-string file:///dev/stdin \
        --work-group anp-fuel-prices

# 5. rodar as queries
aws athena start-query-execution \
    --query-string "$(cat aws/sql/02_analytics.sql)" \
    --work-group anp-fuel-prices
```

Ou execute as queries direto no console do Athena (mais prático para iterar).

## Custos esperados

- **S3:** alguns MB → centavos/mês
- **Athena:** US$ 5 por TB escaneado. Cada query roda sobre poucos MB → **frações de centavo**
- **Glue Catalog:** primeiro 1M de objetos = grátis

Total esperado: < **US$ 0,10/mês** com uso ocasional.

## Cleanup

```bash
cd aws/terraform
terraform destroy
```
