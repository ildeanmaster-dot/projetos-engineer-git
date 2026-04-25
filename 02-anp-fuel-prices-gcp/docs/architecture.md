# Arquitetura — Projeto 02 (GCP)

> Para o post no LinkedIn, recriar como imagem 1200×627 em **draw.io**, **Excalidraw** ou **Figma**.

## Fluxo

```
┌─────────────────────────────────────────────┐
│      ANP — CSV público (.gov.br)            │
│      gasolina-etanol-MM-YYYY.csv · UTF-8    │
└─────────────────────┬───────────────────────┘
                      │ HTTPS GET (requests stream)
                      ▼
┌─────────────────────────────────────────────┐
│  shared/ingest_anp.py  --target gcp         │
│  • download streaming                       │
│  • particiona year=YYYY/month=MM            │
│  • google-cloud-storage upload              │
└─────────────────────┬───────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│  GCS: anp-fuel-prices-ildean26              │
│   └── raw/anp/                              │
│         ├── year=2026/month=03/file.csv     │
│         ├── year=2026/month=04/file.csv     │
│         └── ...                             │
│  • uniform bucket-level access              │
│  • public access enforced=OFF               │
└─────────────────────┬───────────────────────┘
                      │ Hive partitioning AUTO
                      ▼
┌─────────────────────────────────────────────┐
│  BigQuery External Table                    │
│  anp_fuel_prices.weekly_prices_raw          │
│  • schema fixo declarado no Terraform       │
│  • zero storage cost (lê direto do GCS)     │
│  • US$ 5 / TB · 1 TB grátis/mês             │
└─────────────────────┬───────────────────────┘
                      │
                      ▼
            ┌───────────────────┐
            │ 3 queries de KPI  │
            │ • preço médio/UF  │
            │ • série temporal  │
            │ • top municípios  │
            └───────────────────┘
```

## Diferencial vs AWS

- **Tabela externa criada inteiramente no Terraform** com `google_bigquery_table` + `external_data_configuration`. Não precisa rodar `CREATE EXTERNAL TABLE` em SQL como no Athena.
- **1 TB/mês grátis** de query no BigQuery → custo total para esse projeto fica em **US$ 0**.
- **Hive partitioning AUTO** descobre as partições sem nenhuma configuração extra.

## Elementos para o infográfico

- Fluxo top→bottom em 1 coluna
- Logos: GCS, BigQuery
- Cor dominante: azul GCP (#4285F4) com toques de amarelo (#FBBC05)
- Caixa lateral destacando: "1 declaração Terraform · 0 SQL DDL · US$ 0/mês"
- Tamanho final: 1200×627 px (formato feed LinkedIn)
