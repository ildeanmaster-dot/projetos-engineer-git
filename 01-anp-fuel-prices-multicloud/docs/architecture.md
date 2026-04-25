# Diagrama de Arquitetura — Projeto 01

> Versão textual. Para o post no LinkedIn, recriar como imagem 1200×627 em **draw.io**, **Excalidraw**, **Figma** ou **diagrams.net** seguindo este layout.

## Visão geral (multi-cloud paralela)

```
                     ┌──────────────────────────────────────────────┐
                     │  ANP — Levantamento Semanal de Preços (.csv) │
                     │       gov.br/anp · público · ISO-8859-1      │
                     └───────────────────────┬──────────────────────┘
                                             │
                                             ▼
                              ┌────────────────────────────┐
                              │  shared/ingest_anp.py      │
                              │  • requests · streaming    │
                              │  • particiona year=/month= │
                              │  • --target {aws,azure,gcp}│
                              └──┬─────────┬──────────┬────┘
                                 │         │          │
                ┌────────────────┘         │          └──────────────────┐
                ▼                          ▼                             ▼
   ┌───────────────────────┐   ┌────────────────────────┐   ┌──────────────────────┐
   │       AWS             │   │        Azure           │   │         GCP          │
   │                       │   │                        │   │                      │
   │  ┌─────────────────┐  │   │  ┌──────────────────┐  │   │  ┌────────────────┐  │
   │  │  S3 (raw)       │  │   │  │  ADLS Gen2 (raw) │  │   │  │  GCS (raw)     │  │
   │  │  year=YYYY/     │  │   │  │  year=YYYY/      │  │   │  │  year=YYYY/    │  │
   │  │   month=MM/     │  │   │  │   month=MM/      │  │   │  │   month=MM/    │  │
   │  └────────┬────────┘  │   │  └────────┬─────────┘  │   │  └────────┬───────┘  │
   │           │           │   │           │            │   │           │          │
   │           ▼           │   │           ▼            │   │           ▼          │
   │  ┌─────────────────┐  │   │  ┌──────────────────┐  │   │  ┌────────────────┐  │
   │  │ Glue Catalog +  │  │   │  │ Synapse          │  │   │  │  BigQuery      │  │
   │  │ Athena          │  │   │  │ Serverless SQL   │  │   │  │  External      │  │
   │  │ (partition      │  │   │  │ (OPENROWSET +    │  │   │  │  Table         │  │
   │  │  projection)    │  │   │  │  filepath())     │  │   │  │  (Hive Auto)   │  │
   │  └────────┬────────┘  │   │  └────────┬─────────┘  │   │  └────────┬───────┘  │
   └───────────┼───────────┘   └───────────┼────────────┘   └───────────┼──────────┘
               │                           │                            │
               └───────────────────────────┼────────────────────────────┘
                                           ▼
                          ┌─────────────────────────────────┐
                          │   3 queries idênticas           │
                          │   • preço médio diesel/UF       │
                          │   • série temporal gasolina     │
                          │   • top 10 etanol caro          │
                          │                                 │
                          │   → mesmo resultado nas 3 clouds│
                          └─────────────────────────────────┘
```

## Detalhe de uma cloud (ex.: AWS)

```
        ┌──────────────────┐
        │   ANP CSV (URL)  │
        └─────────┬────────┘
                  │ HTTPS GET (requests, stream)
                  ▼
        ┌──────────────────┐
        │ ingest_anp.py    │
        │ --target aws     │
        └─────────┬────────┘
                  │ boto3 upload_file
                  ▼
        ┌──────────────────────────────────────┐
        │ s3://bucket/raw/anp/                 │
        │   ├── year=2026/month=04/file.csv    │
        │   ├── year=2026/month=05/file.csv    │
        │   └── ...                             │
        └─────────┬────────────────────────────┘
                  │ partition projection (sem Crawler)
                  ▼
        ┌──────────────────────────────────────┐
        │ Glue Catalog                          │
        │   anp_fuel_prices.weekly_prices_raw   │
        │   PARTITIONED BY (year int, month int)│
        └─────────┬────────────────────────────┘
                  │ schema-on-read (OpenCSVSerde)
                  ▼
        ┌──────────────────────────────────────┐
        │ Athena Workgroup: anp-fuel-prices     │
        │   results → s3://...-athena-results/  │
        └──────────────────────────────────────┘
```

## Elementos para o infográfico do post LinkedIn

- **Layout:** 3 colunas verticais (uma por cloud), com fluxo top-down idêntico
- **Topo:** ícone único da ANP (CSV gov.br) com seta apontando para `ingest_anp.py`
- **Meio:** caixa de cada cloud com **logo do storage → logo do engine SQL**
- **Base:** caixa única de "queries idênticas → mesmo resultado"
- **Lateral:** badge "Terraform" repetido 3x e "Python" 1x
- **Cores sugeridas:** AWS laranja (#FF9900), Azure azul (#0078D4), GCP multicolor
- **Fonte:** Inter ou IBM Plex Sans para legibilidade no feed mobile
- **Tamanho final:** 1200×627 px (formato ideal LinkedIn)
