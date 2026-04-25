# Posts do LinkedIn — Projeto 01

3 posts encadeados na mesma semana, terça/quarta/quinta entre 10h e 14h.

---

## Post 1 — Terça (AWS)

**Título sugerido:** Pipeline serverless de ponta a ponta na AWS — preços de combustíveis da ANP em ~30 minutos

**Hook (primeira linha, antes do "ver mais"):**
Construí um pipeline de Engenharia de Dados completo na AWS com S3 + Glue + Athena, e o custo mensal previsto é menor que R$ 0,50.

**Corpo:**
Estou começando uma esteira de projetos de Engenharia de Dados que vai sair semanalmente aqui no LinkedIn. A regra é: cada projeto sai em **AWS, Azure e GCP em paralelo**, para a gente comparar arquitetura, sintaxe e custo lado a lado.

O projeto 01 é o mais simples possível, mas já cobre toda a cadeia básica de DE:
🔹 Ingestão Python (CSV semanal da ANP)
🔹 Storage particionado por ano/mês (S3)
🔹 Catálogo de dados (Glue) com partition projection
🔹 Query analítica serverless (Athena)
🔹 IaC com Terraform

3 queries de negócio prontas: preço médio do diesel por UF, série temporal nacional da gasolina, top 10 municípios mais caros para etanol.

Tudo aberto no GitHub: [link]

Quarta-feira sai a versão GCP. Quinta sai Azure + comparativo. Bora?

**Hashtags:**
#DataEngineering #AWS #Athena #Terraform #DadosAbertos #ANP #BigData #Cloud #IaC

---

## Post 2 — Quarta (GCP)

**Título sugerido:** Mesmo pipeline da ANP, agora no GCP — BigQuery External Table em uma única DDL

**Hook:**
Ontem foi AWS. Hoje é GCP. Mesmo pipeline, sintaxe diferente — e tem uma simplificação interessante.

**Corpo:**
Continuando a esteira multi-cloud. O pipeline é o mesmo de ontem (CSV semanal da ANP → object storage → SQL serverless), mas agora rodando em GCP.

A diferença que mais me chamou atenção: no GCP a tabela externa do BigQuery é **declarada uma vez no Terraform** com `google_bigquery_table` + `external_data_configuration`, com Hive partitioning automático. Sem CREATE EXTERNAL TABLE em SQL, sem MSCK REPAIR, sem Crawler.

Já na AWS precisei combinar Terraform (Glue DB + Athena workgroup) com um script SQL que cria a tabela externa via OpenCSVSerde + partition projection. Funciona muito bem, mas são duas etapas em vez de uma.

Custo previsto na GCP: literalmente **R$ 0** no primeiro mês — o BigQuery dá 1 TB/mês de query grátis, e a tabela externa não cobra storage adicional (os dados ficam no GCS).

Código no GitHub: [link]

Amanhã: Azure (Synapse Serverless) + comparativo das três.

**Hashtags:**
#DataEngineering #GCP #BigQuery #Terraform #DadosAbertos #ANP #Cloud #IaC #MultiCloud

---

## Post 3 — Quinta (Azure + comparativo)

**Título sugerido:** Pipeline da ANP completo nas 3 clouds — o que aprendi comparando AWS, Azure e GCP

**Hook:**
Mesmo pipeline. Três clouds. O que mudou — e o que NÃO mudou.

**Corpo:**
Fechando a primeira semana da esteira de portfólio com a versão Azure + um comparativo direto.

No Azure usei **ADLS Gen2 + Synapse Serverless SQL Pool**. O modelo é o mais parecido com Athena: você declara um DATA SOURCE e usa OPENROWSET com FILEPATH() para extrair as partições do path. Funcionou, mas foi o que deu mais trabalho de configurar (managed identity + role assignment + firewall do workspace).

📊 **Comparativo das 3:**

| Aspecto                | AWS              | Azure              | GCP             |
|------------------------|------------------|--------------------|-----------------|
| Tempo até primeira query | ~25 min          | ~40 min            | ~15 min          |
| Linhas de Terraform    | ~80              | ~110               | ~80             |
| Modelo de cobrança     | $5/TB            | $5/TB              | 1TB grátis/mês   |
| DDL de tabela externa  | SQL              | SQL (OPENROWSET)   | Terraform        |
| Custo previsto/mês     | < US$ 0,10       | < US$ 0,10         | US$ 0            |

🎯 **O que NÃO mudou:** o código Python de ingestão, a estrutura de partições (`year=YYYY/month=MM`), e — o mais importante — **o resultado das queries**. Preço médio do diesel por UF na última semana: a mesma tabela nas três clouds.

Esse é o ponto principal: arquitetura serverless pay-per-query democratizou pipelines de DE. Não existe mais "mais barato" óbvio entre as três para casos pequenos — escolha por familiaridade do time, ecossistema e tooling.

Repositório completo: [link]

Próxima semana: projeto 02 — adicionando orquestração agendada. Bora?

**Hashtags:**
#DataEngineering #MultiCloud #AWS #Azure #GCP #Athena #Synapse #BigQuery #Terraform #ANP #DadosAbertos

---

## Lista de melhorias para o infográfico (architecture.png)

- 1 imagem horizontal 1200×627 (formato ideal pro feed do LinkedIn)
- 3 colunas paralelas, 1 por cloud, com mesmo fluxo: CSV → bucket → catálogo → query
- Logos dos serviços (S3, Glue, Athena / ADLS, Synapse / GCS, BigQuery)
- Caixinha lateral com "mesmo Python, mesmo Terraform, 3 outputs idênticos"
- Ferramentas sugeridas: draw.io, Excalidraw, Figma ou diagrams.net
