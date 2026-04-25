# Post LinkedIn — Projeto 03 (Azure + Comparativo Multi-cloud)

**Quando publicar:** Quinta, 10h–14h
**Imagem:** infográfico 1200×627 baseado em [architecture.md](./architecture.md) **+ tabela comparativa**

---

## Hook

Mesmo pipeline da ANP. Três clouds. O que mudou — e o que NÃO mudou.

## Corpo

Fechando a primeira semana da esteira de portfólio com o **Projeto 03 — Azure** e o comparativo direto entre as três clouds.

No Azure usei **ADLS Gen2 + Synapse Serverless SQL Pool**. O modelo é o mais parecido com Athena: você declara um `EXTERNAL DATA SOURCE` e usa `OPENROWSET` com `filepath()` para extrair as partições do path. Funcionou, mas foi o que deu mais trabalho de configurar:

🔧 hierarchical namespace ligado no storage (HNS = ADLS Gen2)
🔧 managed identity do Synapse com role `Storage Blob Data Contributor`
🔧 firewall do workspace liberando IP
🔧 provider `Microsoft.Synapse` registrado na subscription

📊 **Comparativo das 3 clouds (mesmo pipeline):**

| Aspecto                     | AWS               | Azure                  | GCP                |
|-----------------------------|-------------------|------------------------|--------------------|
| Tempo até primeira query    | ~25 min           | ~40 min                | ~15 min            |
| Linhas de Terraform         | ~95               | ~140                   | ~85                |
| Modelo de cobrança          | $5/TB             | $5/TB                  | 1 TB grátis/mês    |
| DDL de tabela externa       | SQL (OpenCSVSerde)| SQL (OPENROWSET)       | Terraform          |
| Encoding suportado          | UTF-8 (default)   | UTF-8 (parser v2.0)    | UTF-8 (configurável)|
| Custo previsto/mês          | < US$ 0,10        | < US$ 0,10             | US$ 0              |
| Setup mais complexo         | -                 | ✅ (managed identity)  | -                  |

🎯 **O que NÃO mudou:** o código Python de ingestão (boto3 vs azure-storage-blob vs google-cloud-storage só varia o cliente), a estrutura de partições (`year=YYYY/month=MM`), e — o mais importante — **o resultado das queries**. Preço médio da gasolina por UF na partição mais recente: **a mesma tabela nas três clouds**.

Esse é o ponto principal: arquitetura serverless pay-per-query democratizou pipelines de DE. Não existe mais "mais barato" óbvio entre as três para casos pequenos — escolha por familiaridade do time, ecossistema e tooling.

3 repositórios separados no GitHub (um por cloud), código aberto, infra reproduzível com `terraform apply`:
- 📁 [Projeto 01 — AWS](link)
- 📁 [Projeto 02 — GCP](link)
- 📁 [Projeto 03 — Azure](link)

Próxima semana começa o **bloco 2 da esteira: orquestração agendada** (Step Functions / Logic Apps / Cloud Workflows). Bora?

## Hashtags

#DataEngineering #MultiCloud #AWS #Azure #GCP #Athena #Synapse #BigQuery #Terraform #ANP #DadosAbertos #PortfolioDE
