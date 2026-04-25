# Post LinkedIn — Projeto 02 (GCP)

**Quando publicar:** Quarta, 10h–14h
**Imagem:** infográfico 1200×627 baseado em [architecture.md](./architecture.md)

---

## Hook

Ontem foi AWS. Hoje é GCP. Mesmo pipeline da ANP, sintaxe diferente — e tem uma simplificação interessante que mudou meu jeito de pensar IaC para data.

## Corpo

Continuando a esteira multi-cloud de Engenharia de Dados. Hoje é o **Projeto 02 — GCP** com **Cloud Storage + BigQuery External Table**.

A fonte é a mesma do Projeto 01: CSV mensal da ANP com preços de gasolina e etanol, particionado em `raw/anp/year=YYYY/month=MM/`.

A diferença que mais me chamou atenção entre AWS e GCP:

🔹 **No GCP, a tabela externa do BigQuery é declarada UMA vez no Terraform** com `google_bigquery_table` + `external_data_configuration`. Hive partitioning automático. Sem CREATE EXTERNAL TABLE em SQL, sem MSCK REPAIR, sem Crawler.

🔹 **Já na AWS,** precisei combinar Terraform (Glue DB + Athena workgroup) com um script SQL que cria a tabela externa via OpenCSVSerde + partition projection. Funciona muito bem, mas são duas etapas em vez de uma.

Outras diferenças que vão pro post de comparativo amanhã:

✅ **Custo:** GCP tem 1 TB/mês de query grátis no BigQuery. Esse projeto fica em **US$ 0/mês** indefinidamente.
✅ **Tabela externa zero-storage:** dados ficam no GCS, BQ só lê via metadata. Sem duplicação.
✅ **Tempo até primeira query:** ~15 minutos (mais rápido que AWS pra mim).

3 queries idênticas às do projeto 01, só mudando a sintaxe (PARSE_DATE, SAFE_CAST, etc.):
- Preço médio da gasolina por UF
- Série temporal nacional
- Top 10 municípios mais caros

Código no GitHub: [link]

📅 Amanhã: **Projeto 03 — Azure** (Synapse Serverless + OPENROWSET) com comparativo das três clouds.

Bora?

## Hashtags

#DataEngineering #GCP #BigQuery #Terraform #DadosAbertos #ANP #Cloud #IaC #PortfolioDE #MultiCloud
