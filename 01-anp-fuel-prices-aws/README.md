# Projeto 01 — ANP Fuel Prices na AWS

> Pipeline batch serverless: ingere o CSV mensal de preços de combustíveis da ANP, armazena no S3 particionado por ano/mês e disponibiliza via Athena para análise SQL. **Custo previsto: < US$ 0,10/mês.**

## Arquitetura

```
gov.br/anp (CSV UTF-8)
        │  HTTPS GET
        ▼
shared/ingest_anp.py  --target aws
        │  boto3 upload_file
        ▼
S3: s3://anp-fuel-prices-ildean26/raw/anp/year=YYYY/month=MM/<arquivo>.csv
        │  partition projection (sem Crawler!)
        ▼
Glue Catalog: anp_fuel_prices.weekly_prices_raw
        │  schema-on-read (OpenCSVSerde)
        ▼
Athena Workgroup: wg-anp-fuel-prices
        │  consultas SQL ad-hoc
        ▼
Resultados (e.g. preço médio gasolina/UF)
```

## Componentes provisionados pelo Terraform

| Recurso                                | Nome                                | Boas práticas aplicadas |
|----------------------------------------|-------------------------------------|--------------------------|
| `aws_s3_bucket` (raw)                  | `anp-fuel-prices-ildean26`          | lowercase + hyphens, owner+propósito no nome, < 63 chars |
| `aws_s3_bucket` (athena results)       | `<raw>-athena-results`              | bucket separado para resultado de query |
| Encryption                             | SSE-S3 (AES256)                     | encryption-at-rest sempre on |
| Public access                          | bloqueado (4 flags)                 | nunca expor bucket público sem motivo |
| `aws_glue_catalog_database`            | `anp_fuel_prices`                   | snake_case (padrão Glue/Hive) |
| `aws_athena_workgroup`                 | `wg-anp-fuel-prices`                | prefixo `wg-` por tipo de recurso |
| Tags                                   | project/owner/env/managedBy/repo    | rastreabilidade e billing por projeto |

A tabela externa usa **partition projection** (sem `MSCK REPAIR TABLE` ou Glue Crawler) — basta subir o CSV em `raw/anp/year=YYYY/month=MM/` e o Athena descobre a partição automaticamente.

## Pré-requisitos

- AWS CLI configurado (`aws configure`) com permissões de S3, Glue e Athena
- Terraform >= 1.6
- Python 3.10+ e dependências core (já instaladas no `.venv` na raiz do repo)
- SDK boto3: `.venv/Scripts/pip install boto3`

## Passo a passo

```bash
# (1) provisionar a infra
cd 01-anp-fuel-prices-aws/terraform
cp terraform.tfvars.example terraform.tfvars   # ajuste bucket_name se for outra conta
terraform init
terraform apply

BUCKET=$(terraform output -raw raw_bucket)
WORKGROUP=$(terraform output -raw athena_workgroup)
echo "bucket=$BUCKET  workgroup=$WORKGROUP"
cd ../..

# (2) configurar o ingest (na raiz)
cp shared/config.example.yaml shared/config.yaml
# edite shared/config.yaml: aws.bucket = $BUCKET, aws.region, aws.profile

# (3) baixar e subir o CSV mais recente da ANP (gasolina+etanol mês 03/2026)
.venv/Scripts/python.exe shared/ingest_anp.py \
    --url "https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/shpc/dsan/2026/03-dados-abertos-precos-gasolina-etanol.csv" \
    --target aws \
    --reference-date 2026-03-01

# (4) criar a tabela externa no Athena
# Abra o console: https://console.aws.amazon.com/athena/
# Selecione workgroup "wg-anp-fuel-prices"
# Cole 01-anp-fuel-prices-aws/sql/01_create_external_table.sql substituindo __BUCKET_NAME__ pelo seu bucket
# Execute

# (5) rodar as 3 queries analíticas
# Cole 01-anp-fuel-prices-aws/sql/02_analytics.sql e execute
# (preço médio gasolina/UF, série temporal, top municípios mais caros)
```

## URLs alternativas da ANP

A ANP publica vários datasets — escolha o melhor para seu post:

| Tipo                              | URL pattern                                                                    | Ideal para |
|-----------------------------------|--------------------------------------------------------------------------------|-----------|
| Mensal — gasolina + etanol        | `.../shpc/dsan/YYYY/MM-dados-abertos-precos-gasolina-etanol.csv`               | Esse projeto |
| Mensal — diesel + GNV             | `.../shpc/dsan/YYYY/MM-dados-abertos-precos-diesel-gnv.csv`                    | Variação |
| Últimas 4 semanas (URL estável!)  | `.../shpc/qus/ultimas-4-semanas-gasolina-etanol.csv`                           | Pipeline weekly |
| Histórico semestral               | `.../shpc/dsas/ca/ca-YYYY-0X.zip`                                              | Análise long-term |

Portal: https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/serie-historica-de-precos-de-combustiveis

## Custos esperados

- **S3 storage:** ~10 MB → ~US$ 0,000 23/mês
- **Athena:** US$ 5/TB escaneado. Cada query roda sobre poucos MB → frações de centavo
- **Glue Catalog:** primeiro 1M de objetos = grátis

**Total estimado: < US$ 0,10/mês** com uso ocasional de portfólio.

## Cleanup

```bash
cd 01-anp-fuel-prices-aws/terraform
terraform destroy
```

> O bucket tem `force_destroy = true` para que `terraform destroy` consiga remover mesmo com objetos dentro — útil em portfolio, **NÃO** em produção.

## Posts relacionados

- 📝 Rascunho do post LinkedIn de terça → [docs/linkedin-post.md](./docs/linkedin-post.md)
- 🎨 Diagrama de arquitetura para infográfico → [docs/architecture.md](./docs/architecture.md)
