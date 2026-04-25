# Projeto 03 — ANP Fuel Prices no Azure

> Pipeline batch serverless: ingere o CSV mensal de preços de combustíveis da ANP, armazena no ADLS Gen2 particionado por ano/mês e disponibiliza via Synapse Serverless SQL Pool. **Custo previsto: < US$ 0,10/mês.**

## Arquitetura

```
gov.br/anp (CSV UTF-8)
        │  HTTPS GET
        ▼
shared/ingest_anp.py  --target azure
        │  azure-storage-blob upload (DefaultAzureCredential)
        ▼
ADLS Gen2: stanpfuelildean26/raw/anp/year=YYYY/month=MM/<arquivo>.csv
        │  managed identity tem Storage Blob Data Contributor
        ▼
Synapse Serverless SQL Pool (OPENROWSET com filepath())
        │  view dbo.weekly_prices_raw extrai partições do path
        ▼
Resultados (e.g. preço médio gasolina/UF)
```

## Componentes provisionados pelo Terraform

| Recurso                        | Nome                              | Boas práticas aplicadas |
|--------------------------------|-----------------------------------|--------------------------|
| `azurerm_resource_group`       | `rg-anp-fuel-prices`              | prefixo `rg-` (CAF) + propósito |
| `azurerm_storage_account`      | `stanpfuelildean26`               | prefixo `st`, lowercase, alfanum, ≤24 chars |
| TLS                            | `min_tls_version = TLS1_2`        | nunca aceitar TLS1.0/1.1 |
| Hierarchical namespace (HNS)   | `is_hns_enabled = true`           | habilita ADLS Gen2 (paths "/" reais) |
| `azurerm_synapse_workspace`    | `synw-anp-fuel-prices-ildean`     | prefixo `synw-` (CAF) |
| Managed identity               | SystemAssigned                     | sem secrets de service principal |
| Role assignment                | Storage Blob Data Contributor     | least-privilege para o Synapse |
| Tags                           | project/owner/env/managed_by      | rastreabilidade |

> ⚠️ **Por que Synapse Serverless e não Microsoft Fabric?** Fabric tem custo fixo de capacity (mínimo F2 ≈ US$ 250/mês), enquanto Synapse Serverless cobra US$ 5/TB escaneado, sem custo ocioso — alinhado com o modelo serverless dos projetos 01 e 02.

## Pré-requisitos

- Azure CLI: `az login`
- Subscription ativa: `az account set --subscription <id>`
- Provider do Synapse registrado (uma vez por subscription):
  ```bash
  az provider register --namespace Microsoft.Synapse
  ```
- Terraform >= 1.6
- Python 3.10+ e `.venv` na raiz com `pip install azure-identity azure-storage-blob`

## Passo a passo

```bash
# (1) provisionar a infra
cd 03-anp-fuel-prices-azure/terraform
cp terraform.tfvars.example terraform.tfvars   # ajuste storage_account_name, synapse_workspace_name
export TF_VAR_synapse_admin_password='SuaSenhaForte123!'
terraform init
terraform apply

STORAGE=$(terraform output -raw storage_account)
WORKSPACE=$(terraform output -raw synapse_workspace)
ENDPOINT=$(terraform output -raw synapse_serverless_endpoint)
echo "storage=$STORAGE  workspace=$WORKSPACE  endpoint=$ENDPOINT"
cd ../..

# (2) configurar o ingest
cp shared/config.example.yaml shared/config.yaml
# edite shared/config.yaml: azure.storage_account = $STORAGE

# (3) baixar e subir o CSV
.venv/Scripts/python.exe shared/ingest_anp.py \
    --url "https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/shpc/dsan/2026/03-dados-abertos-precos-gasolina-etanol.csv" \
    --target azure \
    --reference-date 2026-03-01

# (4) abrir o Synapse Studio: https://web.azuresynapse.net
#     Selecione o workspace $WORKSPACE
#     SQL Script → conectar no pool "Built-in" (serverless)
#     Cole 03-anp-fuel-prices-azure/sql/01_create_external_table.sql substituindo:
#         __STORAGE_ACCOUNT__ → $STORAGE
#         __CONTAINER__       → raw
#     Execute
#     Cole 02_analytics.sql e execute as 3 queries
```

## Custos esperados

- **ADLS Gen2:** ~10 MB → centavos/mês
- **Synapse Serverless SQL Pool:** US$ 5/TB escaneado, **sem custo fixo** (workspace ocioso = US$ 0)
- Cada query roda sobre poucos MB → frações de centavo

**Total estimado: < US$ 0,10/mês.**

## Cleanup

```bash
cd 03-anp-fuel-prices-azure/terraform
terraform destroy
```

> Esse `destroy` remove inclusive o resource group, com todos os recursos dentro.

## Posts relacionados

- 📝 Rascunho do post LinkedIn de quinta (com comparativo) → [docs/linkedin-post.md](./docs/linkedin-post.md)
- 🎨 Diagrama de arquitetura → [docs/architecture.md](./docs/architecture.md)
