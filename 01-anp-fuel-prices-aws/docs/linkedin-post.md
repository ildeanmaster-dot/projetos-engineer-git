# Post LinkedIn — Projeto 01 (AWS)

**Quando publicar:** Terça, 10h–14h
**Imagem:** infográfico 1200×627 baseado em [architecture.md](./architecture.md)

---

## Hook (primeira linha — antes do "ver mais")

Construí um pipeline de Engenharia de Dados ponta a ponta na AWS por menos de 1 centavo de dólar por mês. Compartilho a arquitetura e o código aberto.

## Corpo

Estou começando uma esteira de projetos de Engenharia de Dados que vai sair semanalmente aqui no LinkedIn. A regra é: cada conceito sai em **AWS, Azure e GCP em projetos separados**, para a gente comparar arquitetura, sintaxe e custo lado a lado.

Hoje é o **Projeto 01 — AWS**.

A fonte de dados é o CSV mensal de preços de combustíveis publicado pela ANP (gov.br), com 16 colunas e ~milhares de pontos de coleta por mês — UF, município, posto, bandeira, produto, preço de venda e compra.

Stack:
🔹 **Python + requests** para ingestão streaming
🔹 **S3** com particionamento year=YYYY/month=MM
🔹 **Glue Data Catalog** com partition projection (sem Crawler!)
🔹 **Athena** (workgroup dedicado, results separados)
🔹 **Terraform** com tags padronizadas (project/owner/env)

Boas práticas aplicadas:
✅ encryption SSE-S3 ligada por padrão
✅ public access bloqueado (4 flags)
✅ workgroup dedicado com result_location separado
✅ partition projection elimina necessidade de Crawler agendado

3 queries de negócio prontas no SQL: preço médio da gasolina por UF, série temporal nacional, top 10 municípios mais caros.

Resultado: pipeline funcional em ~25 minutos do `terraform apply` à primeira query, custo previsto < US$ 0,10/mês.

Código aberto no GitHub: [link]

📅 Quarta-feira sai o **Projeto 02 — GCP** (BigQuery External Table)
📅 Quinta-feira sai o **Projeto 03 — Azure** (Synapse Serverless) com comparativo das três

Bora?

## Hashtags

#DataEngineering #AWS #Athena #Terraform #DadosAbertos #ANP #BigData #Cloud #IaC #PortfolioDE
