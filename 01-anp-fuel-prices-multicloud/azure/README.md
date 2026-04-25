# Azure — ANP Fuel Prices

Implementação no Azure usando **ADLS Gen2 + Synapse Serverless SQL Pool**.

## Arquitetura

```
ANP CSV → ingest_anp.py → ADLS Gen2 (raw, partição year/month) → Synapse Serverless (OPENROWSET) → resultado
```

Componentes provisionados pelo Terraform:
- `azurerm_resource_group.rg`
- `azurerm_storage_account.data` — Storage V2 com hierarchical namespace (ADLS Gen2)
- `azurerm_storage_data_lake_gen2_filesystem.raw` — container `raw` para os CSVs
- `azurerm_synapse_workspace.ws` — workspace Synapse (o pool serverless já vem incluso, sem custo fixo)
- `azurerm_role_assignment` — concede ao Synapse leitura no storage

> **Por que Synapse Serverless e não Microsoft Fabric?** Fabric tem custo fixo de capacity (mínimo F2 ≈ US$ 250/mês), enquanto Synapse Serverless cobra US$ 5/TB escaneado, sem custo ocioso — alinhado com o modelo serverless dos outros dois clouds.

## Pré-requisitos

- Azure CLI: `az login`
- Subscription ativa: `az account set --subscription <id>`
- Terraform >= 1.6
- Python 3.10+ e `pip install -r ../shared/requirements.txt`

## Passo a passo

```bash
# 1. provisionar a infra
cd azure/terraform
cp terraform.tfvars.example terraform.tfvars   # ajuste storage_account_name, synapse_workspace_name
export TF_VAR_synapse_admin_password='SuaSenhaForte!'
terraform init
terraform apply

STORAGE=$(terraform output -raw storage_account)
WORKSPACE=$(terraform output -raw synapse_workspace)
ENDPOINT=$(terraform output -raw synapse_serverless_endpoint)
cd ../..

# 2. configurar o ingest
cp shared/config.example.yaml shared/config.yaml
# edite shared/config.yaml — preencha azure.storage_account com $STORAGE

# 3. baixar e subir o CSV semanal da ANP
python shared/ingest_anp.py \
    --url "https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/...csv" \
    --target azure

# 4. abrir o Synapse Studio: https://web.azuresynapse.net  → workspace $WORKSPACE
#    No SQL Script, conectar no pool "Built-in" (serverless) e executar:
#       a) azure/sql/01_create_external_table.sql  (substituindo __STORAGE_ACCOUNT__ e __CONTAINER__)
#       b) azure/sql/02_analytics.sql

# Alternativa via sqlcmd:
sqlcmd -S "$ENDPOINT" -d master -G \
       -i azure/sql/01_create_external_table.sql
```

## Custos esperados

- **ADLS Gen2:** alguns MB → centavos/mês
- **Synapse Serverless SQL Pool:** US$ 5 por TB escaneado, sem custo fixo. Workspace em si não cobra ocioso.
- Cada query roda sobre poucos MB → frações de centavo.

Total esperado: < **US$ 0,10/mês**.

## Cleanup

```bash
cd azure/terraform
terraform destroy
```
