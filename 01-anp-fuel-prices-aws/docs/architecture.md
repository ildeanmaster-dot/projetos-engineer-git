# Arquitetura — Projeto 01 (AWS)

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
│  shared/ingest_anp.py  --target aws         │
│  • download streaming                       │
│  • particiona year=YYYY/month=MM            │
│  • boto3 upload_file                        │
└─────────────────────┬───────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│  S3: anp-fuel-prices-ildean26               │
│   └── raw/anp/                              │
│         ├── year=2026/month=03/file.csv     │
│         ├── year=2026/month=04/file.csv     │
│         └── ...                             │
│  • SSE-S3 encryption · public access OFF    │
└─────────────────────┬───────────────────────┘
                      │ partition projection (sem Crawler!)
                      ▼
┌─────────────────────────────────────────────┐
│  Glue Data Catalog                          │
│   └── database: anp_fuel_prices             │
│         └── table: weekly_prices_raw        │
│  • schema-on-read · OpenCSVSerde            │
│  • PARTITIONED BY (year int, month int)     │
└─────────────────────┬───────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│  Athena Workgroup: wg-anp-fuel-prices       │
│  • result_location separado                 │
│  • US$ 5 / TB escaneado                     │
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

## Por que esta combinação

- **S3 + partition projection:** elimina necessidade de Crawler agendado. Cada arquivo novo aparece "magicamente" como partição.
- **Glue Catalog + Athena:** schema-on-read, paga por query, zero ocioso. Ideal para portfolio.
- **OpenCSVSerde:** lida com `;` separator e quoting, sem dependência externa.

## Elementos para o infográfico

- Fluxo top→bottom em 1 coluna (não comparativo, é projeto AWS-only)
- Logos: AWS S3, AWS Glue, AWS Athena
- Cor dominante: laranja AWS (#FF9900)
- Caixa lateral destacando: "0 servidores · pay-per-query · ~US$ 0,10/mês"
- Tamanho final: 1200×627 px (formato feed LinkedIn)
