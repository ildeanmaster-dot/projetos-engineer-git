# Arquitetura — Projeto 03 (Azure)

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
│  shared/ingest_anp.py  --target azure       │
│  • download streaming                       │
│  • particiona year=YYYY/month=MM            │
│  • azure-storage-blob upload                │
│  • DefaultAzureCredential (az login)        │
└─────────────────────┬───────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│  ADLS Gen2: stanpfuelildean26               │
│   └── raw/anp/                              │
│         ├── year=2026/month=03/file.csv     │
│         ├── year=2026/month=04/file.csv     │
│         └── ...                             │
│  • TLS 1.2 mínimo                           │
│  • managed identity → blob reader           │
└─────────────────────┬───────────────────────┘
                      │ OPENROWSET com filepath()
                      ▼
┌─────────────────────────────────────────────┐
│  Synapse Serverless SQL Pool (Built-in)     │
│  • view dbo.weekly_prices_raw               │
│  • PARSER_VERSION 2.0 (UTF-8)               │
│  • US$ 5 / TB · sem custo ocioso            │
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

## Diferencial vs AWS e GCP

- **Schema na hora da query** (não declarado em catálogo prévio): a view `dbo.weekly_prices_raw` faz `OPENROWSET ... WITH (...)` com tipos por coluna. Mais flexível, mas exige que toda query passe pela view.
- **`filepath(N)`** extrai a N-ésima parte do path com curinga — poderoso e específico do Synapse Serverless.
- **Workspace gratuito ocioso:** o SQL Pool serverless não tem custo fixo, igual Athena e BQ.

## Setup mais complexo dos três

A AWS e o GCP exigem só "bucket + catálogo". O Azure exige adicionalmente:
- **Hierarchical namespace** ligado no storage (HNS = ADLS Gen2)
- **Managed identity do Synapse com role no storage**
- **Firewall do workspace** liberando seu IP
- **Provider Microsoft.Synapse registrado** na subscription

Por isso o post de quinta abre com isso e fecha com a tabela comparativa das 3 clouds.

## Elementos para o infográfico

- Fluxo top→bottom em 1 coluna
- Logos: ADLS Gen2, Azure Synapse
- Cor dominante: azul Azure (#0078D4)
- Caixa lateral: "managed identity · TLS 1.2 · zero ocioso"
- Tamanho final: 1200×627 px (formato feed LinkedIn)
