# Handoff — Ações que dependem de você

> Tudo que pode ser feito automaticamente foi feito. Esta lista é o que **só você** pode fazer porque exige credenciais, contas, decisões pessoais ou ação manual em UI externa.

## Status atual

- [x] Repositório com **3 projetos separados** + `shared/` na raiz, conforme estrutura final
- [x] `git init` + branch `main` + commits da estrutura
- [x] Venv Python `.venv/` criado e dependências core (`requests`, `pandas`, `PyYAML`) instaladas
- [x] Script `shared/ingest_anp.py` validado (sintaxe OK, helpers passam, `--help` funciona)
- [x] Diagrama + post LinkedIn por cloud em cada projeto
- [x] Nomes de recursos seguindo boas práticas de cada cloud (ver tabela abaixo)
- [x] URL exata do CSV ANP no README de cada projeto e nesse handoff
- [x] CSV sintético de teste em `shared/sample/anp_sample.csv`
- [ ] Itens 1, 2, 6, 7, 8 abaixo dependem de você

## URL da ANP a ser usada

O CSV mensal de **gasolina + etanol** publicado pela ANP (UTF-8, 16 colunas):

```
https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/shpc/dsan/2026/03-dados-abertos-precos-gasolina-etanol.csv
```

Esse já está embutido nos passos abaixo. Para usar mês mais recente (04, 05...), troque `03` na URL. Outros datasets disponíveis estão listados na seção "URLs alternativas" do [README do projeto AWS](./01-anp-fuel-prices-aws/README.md).

## Nomes escolhidos (boas práticas aplicadas)

Como você pediu para eu escolher seguindo as convenções de cada cloud:

| Cloud  | Recurso                  | Nome escolhido                          | Justificativa |
|--------|--------------------------|-----------------------------------------|---------------|
| AWS    | bucket S3 (raw)          | `anp-fuel-prices-ildean26`              | lowercase + hyphens, owner+propósito + sufixo curto, < 63 chars |
| AWS    | bucket Athena results    | `anp-fuel-prices-ildean26-athena-results` | bucket separado para resultado de query (boa prática) |
| AWS    | Glue database            | `anp_fuel_prices`                       | snake_case (padrão Hive/Glue) |
| AWS    | Athena workgroup         | `wg-anp-fuel-prices`                    | prefixo `wg-` por tipo de recurso |
| Azure  | resource group           | `rg-anp-fuel-prices`                    | prefixo `rg-` (padrão CAF) |
| Azure  | storage account          | `stanpfuelildean26`                     | prefixo `st`, alfanum-only, 17/24 chars |
| Azure  | synapse workspace        | `synw-anp-fuel-prices-ildean`           | prefixo `synw-` (CAF) |
| GCP    | GCS bucket               | `anp-fuel-prices-ildean26`              | igual AWS (namespace separado) |
| GCP    | BigQuery dataset         | `anp_fuel_prices`                       | snake_case (padrão BQ) |
| GCP    | BigQuery table           | `weekly_prices_raw`                     | sufixo `_raw` indica camada bronze |
| Todos  | tags/labels              | project, owner, env, managed_by, repo   | rastreabilidade e billing por projeto |

> Se outra pessoa for clonar e rodar, basta trocar o sufixo `ildean26` em `terraform.tfvars` (são únicos globalmente).

---

## Passo a passo do que **você** precisa fazer

### 1. Instalar as ferramentas locais que faltam

| Ferramenta            | Por quê                                  | Onde baixar |
|-----------------------|-------------------------------------------|-------------|
| Terraform >= 1.6      | Provisionar infra nas 3 clouds            | https://developer.hashicorp.com/terraform/downloads |
| AWS CLI               | Autenticar e operar AWS                   | https://aws.amazon.com/cli/ |
| Azure CLI (`az`)      | Autenticar e operar Azure                 | https://learn.microsoft.com/cli/azure/install-azure-cli |
| Google Cloud CLI      | Autenticar e operar GCP                   | https://cloud.google.com/sdk/docs/install |

Confira depois com:
```bash
terraform --version && aws --version && az --version && gcloud --version
```

### 2. Criar / liberar contas nas 3 clouds

Você precisa de **uma conta com cartão cadastrado** em cada cloud (todas têm free tier para esse projeto, mas exigem cartão).

- **AWS:** https://aws.amazon.com/free/ — após criar, rode `aws configure` (perfil `default`)
- **Azure:** https://azure.microsoft.com/free/ — US$ 200 / 30 dias para conta nova. Rode `az login`
- **GCP:** https://cloud.google.com/free — US$ 300 / 90 dias. Crie um projeto novo, depois:
  ```bash
  gcloud auth application-default login
  gcloud config set project <SEU-PROJECT-ID>
  gcloud services enable storage.googleapis.com bigquery.googleapis.com
  ```

> ⚠️ **Configure billing alerts** em cada cloud (limite ~US$ 5/mês) **antes** de qualquer `terraform apply`. Custo real do projeto é centavos, mas alerta protege contra erros de configuração.

### 3. Subir para o GitHub _(eu já vou fazer pra você quando rodar este handoff — pule este item)_

Depois de revisar tudo, eu vou rodar:
```bash
gh repo create projetos-engineer-git \
    --public \
    --source=. \
    --description="Esteira de projetos de Engenharia de Dados multi-cloud (AWS/Azure/GCP)" \
    --push
```

Confira em https://github.com/ildeanmaster-dot/projetos-engineer-git depois.

### 4. _Não precisa fazer nada_ — URL já está embutida

A URL do CSV ANP já está nos READMEs e nos exemplos. Use a URL exata que aparece na seção "URL da ANP a ser usada" no topo deste arquivo.

### 5. _Não precisa fazer nada_ — nomes já escolhidos

Os `terraform.tfvars.example` e `shared/config.example.yaml` já vêm preenchidos com os nomes das tabelas acima. Basta copiar para `terraform.tfvars` / `config.yaml` e ajustar **apenas** o `project` do GCP (que é específico da sua conta) e a senha do admin do Synapse.

### 6. Rodar o Projeto 01 — AWS (post de terça)

```bash
# (1) instale boto3 no venv
.venv/Scripts/python.exe -m pip install boto3

# (2) provisione a infra
cd 01-anp-fuel-prices-aws/terraform
cp terraform.tfvars.example terraform.tfvars      # já preenchido com nomes
terraform init
terraform apply
cd ../..

# (3) configure o ingest (na raiz)
cp shared/config.example.yaml shared/config.yaml  # já preenchido

# (4) baixe e suba o CSV da ANP (URL já fixa no comando)
.venv/Scripts/python.exe shared/ingest_anp.py \
    --url "https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/shpc/dsan/2026/03-dados-abertos-precos-gasolina-etanol.csv" \
    --target aws \
    --reference-date 2026-03-01

# (5) crie a tabela no Athena
# Console: https://console.aws.amazon.com/athena/
# Workgroup: wg-anp-fuel-prices
# Cole 01-anp-fuel-prices-aws/sql/01_create_external_table.sql
# Substitua __BUCKET_NAME__ por anp-fuel-prices-ildean26 (ou seu nome)
# Execute

# (6) rode as queries
# Cole 01-anp-fuel-prices-aws/sql/02_analytics.sql e execute
# Tire screenshot da Query 1 (preço médio gasolina/UF) para o post
```

### 7. Rodar o Projeto 02 — GCP (post de quarta)

```bash
# (1) instale o SDK do GCP
.venv/Scripts/python.exe -m pip install google-cloud-storage

# (2) provisione (a tabela externa já vem do Terraform!)
cd 02-anp-fuel-prices-gcp/terraform
cp terraform.tfvars.example terraform.tfvars
# EDITE: project = "<seu GCP project id>"
terraform init
terraform apply
cd ../..

# (3) atualize shared/config.yaml: gcp.project = <seu project id>

# (4) ingest
.venv/Scripts/python.exe shared/ingest_anp.py \
    --url "https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/shpc/dsan/2026/03-dados-abertos-precos-gasolina-etanol.csv" \
    --target gcp \
    --reference-date 2026-03-01

# (5) BigQuery: https://console.cloud.google.com/bigquery
# Cole 02-anp-fuel-prices-gcp/sql/02_analytics.sql substituindo __PROJECT__ pelo seu id
# Execute as 3 queries — screenshot da Query 1
```

### 8. Rodar o Projeto 03 — Azure (post de quinta + comparativo)

```bash
# (1) instale o SDK do Azure
.venv/Scripts/python.exe -m pip install azure-identity azure-storage-blob

# (2) registre o provider Synapse uma vez na subscription
az provider register --namespace Microsoft.Synapse

# (3) provisione (senha vai por env var)
cd 03-anp-fuel-prices-azure/terraform
cp terraform.tfvars.example terraform.tfvars
export TF_VAR_synapse_admin_password='SuaSenhaForte123!'
terraform init
terraform apply
cd ../..

# (4) ingest (config.yaml já preenchido)
.venv/Scripts/python.exe shared/ingest_anp.py \
    --url "https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/shpc/dsan/2026/03-dados-abertos-precos-gasolina-etanol.csv" \
    --target azure \
    --reference-date 2026-03-01

# (5) Synapse Studio: https://web.azuresynapse.net
# Workspace: synw-anp-fuel-prices-ildean (ou seu nome)
# SQL Script → conectar no pool "Built-in" (serverless)
# Cole 03-anp-fuel-prices-azure/sql/01_create_external_table.sql
# Substitua __STORAGE_ACCOUNT__ por stanpfuelildean26 e __CONTAINER__ por raw
# Execute → depois 02_analytics.sql → screenshots
```

### 9. Verificar paridade entre as 3 clouds

A Query 1 (preço médio da gasolina por UF na partição mais recente) deve retornar **a mesma tabela** nas três clouds: ~27 linhas (UFs do BR), valores em R$ 5–7. Esse é o destaque do post de quinta. Se divergir, há erro de parsing.

### 10. Criar o infográfico de cada post

3 imagens 1200×627 (uma por dia), seguindo o esqueleto em cada `docs/architecture.md`:
- [01-anp-fuel-prices-aws/docs/architecture.md](./01-anp-fuel-prices-aws/docs/architecture.md)
- [02-anp-fuel-prices-gcp/docs/architecture.md](./02-anp-fuel-prices-gcp/docs/architecture.md)
- [03-anp-fuel-prices-azure/docs/architecture.md](./03-anp-fuel-prices-azure/docs/architecture.md)

Use **draw.io**, **Excalidraw** ou **Figma**. Salve cada um como `architecture.png` na respectiva pasta `docs/`.

### 11. Publicar os 3 posts no LinkedIn

Use os rascunhos prontos:
- Terça (10h–14h): [01-anp-fuel-prices-aws/docs/linkedin-post.md](./01-anp-fuel-prices-aws/docs/linkedin-post.md)
- Quarta (10h–14h): [02-anp-fuel-prices-gcp/docs/linkedin-post.md](./02-anp-fuel-prices-gcp/docs/linkedin-post.md)
- Quinta (10h–14h): [03-anp-fuel-prices-azure/docs/linkedin-post.md](./03-anp-fuel-prices-azure/docs/linkedin-post.md) (com comparativo)

Substitua `[link]` pelo URL real do GitHub depois do push.

### 12. Cleanup ao final da semana (opcional, economiza centavos)

Quando os posts virarem só visualizações em vez de tráfego ativo:

```bash
cd 01-anp-fuel-prices-aws/terraform   && terraform destroy && cd ../..
cd 02-anp-fuel-prices-gcp/terraform   && terraform destroy && cd ../..
cd 03-anp-fuel-prices-azure/terraform && terraform destroy && cd ../..
```

Os arquivos no GitHub permanecem como portfólio. Quem quiser ver funcionando recria com `terraform apply`.

---

## Quando estiver pronto para o próximo bloco

**Bloco 2 da esteira (semana 2):** adicionar **orquestração agendada** ao mesmo pipeline:
- Step Functions (AWS) + EventBridge cron
- Logic Apps (Azure) + recurrence trigger
- Cloud Workflows (GCP) + Cloud Scheduler

E também **GitHub Actions** rodando o ingest toda segunda-feira de manhã, automaticamente. Mantém a mesma fonte ANP, evolui complexidade.

Me avise quando terminar o bloco 1 e quiser começar.
