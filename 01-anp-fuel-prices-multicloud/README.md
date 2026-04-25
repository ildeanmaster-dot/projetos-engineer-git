# Projeto 01 — ANP Preços de Combustíveis (Multi-cloud Serverless)

> Pipeline batch que ingere o CSV semanal de preços de combustíveis da **ANP**, armazena em object storage e disponibiliza via SQL serverless. Implementado em paralelo nas três principais clouds para permitir comparativo direto de arquitetura, sintaxe e custo.

## Arquitetura lógica

```
                   ┌───────────────────────────┐
                   │   ANP — CSV público (.gov.br)
                   └─────────────┬─────────────┘
                                 │
                  shared/ingest_anp.py  (Python)
                                 │
        ┌────────────────────────┼────────────────────────┐
        ▼                        ▼                        ▼
   AWS S3                   Azure ADLS Gen2          Google Cloud Storage
        │                        │                        │
        ▼                        ▼                        ▼
   Glue Catalog +           Synapse Serverless        BigQuery External
      Athena                 (OPENROWSET)                Table
        │                        │                        │
        └────────────────────────┴────────────────────────┘
                                 │
                          mesmas 3 queries
                       (paridade de resultado)
```

## Por que esses serviços

| Camada            | AWS                     | Azure                            | GCP                            |
|-------------------|-------------------------|----------------------------------|--------------------------------|
| Object storage    | S3                      | ADLS Gen2 (Storage V2 + HNS)     | Cloud Storage (GCS)            |
| Catálogo / engine | Glue Catalog + Athena   | Synapse Serverless SQL Pool      | BigQuery (External Table)      |
| Modelo de cobrança | $5/TB escaneado         | $5/TB escaneado                  | 1 TB/mês grátis, depois $5/TB  |
| IaC               | Terraform `aws`         | Terraform `azurerm`              | Terraform `google`             |

Todos serverless e pay-per-query. **Custo total esperado nas três clouds: < US$ 0,30/mês** com uso de portfólio.

## Estrutura

```
01-anp-fuel-prices-multicloud/
├── README.md           ← você está aqui
├── docs/
│   ├── architecture.png
│   └── linkedin-post.md
├── shared/             ← código Python comum às 3 clouds
│   ├── ingest_anp.py
│   ├── requirements.txt
│   └── config.example.yaml
├── aws/                ← Terraform + SQL + README específicos
├── azure/
└── gcp/
```

## Como rodar

1. **Escolha a cloud** (ou rode as três em sequência) e siga o README específico:
   - [AWS](./aws/README.md)
   - [GCP](./gcp/README.md)
   - [Azure](./azure/README.md)
2. Ambiente Python (mesmo para qualquer cloud):
   ```bash
   python -m venv .venv
   source .venv/bin/activate         # Windows: .venv\Scripts\activate
   pip install -r shared/requirements.txt
   cp shared/config.example.yaml shared/config.yaml
   ```
3. **Encontre a URL do CSV semanal da ANP**: vá em
   [Série Histórica de Preços de Combustíveis](https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/serie-historica-de-precos-de-combustiveis)
   e copie o link do arquivo desejado. Passe esse link com `--url`.

## Teste de paridade multi-cloud

A query 1 de cada cloud (`02_analytics.sql`) produz **a mesma tabela**: preço médio do diesel por UF na semana mais recente, com ~27 linhas. Confirmar que AWS, Azure e GCP retornam resultados equivalentes é o destaque do post comparativo de quinta-feira.

## Fonte de dados

Agência Nacional do Petróleo, Gás Natural e Biocombustíveis — **Levantamento Semanal de Preços de Combustíveis**.
Schema típico: região, estado, município, revenda, CNPJ, endereço, produto (gasolina, etanol, diesel S10, diesel S500, GLP, GNV), data de coleta, valor de venda e compra, unidade de medida, bandeira.
Encoding: ISO-8859-1 · separador: `;` · decimal: `,` · cabeçalho na linha 1.

## Próximos projetos da esteira

- **02:** orquestração agendada (Step Functions / Logic Apps / Cloud Workflows) ou GitHub Actions
- **03:** camadas Bronze/Silver/Gold em Parquet/Delta com PySpark e/ou Databricks
- **04:** dashboards (QuickSight / Power BI / Looker Studio) sobre as queries deste projeto
