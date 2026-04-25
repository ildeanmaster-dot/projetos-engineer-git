# Esteira de Projetos — Engenharia de Dados Multi-cloud

Repositório público de portfólio em Engenharia de Dados, com projetos práticos desenvolvidos em paralelo nas três principais clouds: **AWS**, **Azure** e **GCP**.

Cada cloud tem **seu próprio projeto**, com README, IaC (Terraform), SQL e rascunho de post LinkedIn próprio. O código Python comum à ingestão fica em [`shared/`](./shared/) na raiz.

## Cadência de publicação

3 posts por semana — terça, quarta e quinta, entre 10h e 14h (horário da audiência BR).

| Dia       | Projeto                                          |
|-----------|--------------------------------------------------|
| Terça     | [Projeto 01 — AWS](./01-anp-fuel-prices-aws/)    |
| Quarta    | [Projeto 02 — GCP](./02-anp-fuel-prices-gcp/)    |
| Quinta    | [Projeto 03 — Azure](./03-anp-fuel-prices-azure/) (com comparativo das três) |

## Projetos

| #  | Projeto                                                          | Storage      | Engine SQL serverless     | Custo previsto/mês |
|----|------------------------------------------------------------------|--------------|---------------------------|---------------------|
| 01 | [ANP Fuel Prices — AWS](./01-anp-fuel-prices-aws/)               | S3           | Athena (Glue Catalog)     | < US$ 0,10          |
| 02 | [ANP Fuel Prices — GCP](./02-anp-fuel-prices-gcp/)               | GCS          | BigQuery External Table   | US$ 0 (free tier)   |
| 03 | [ANP Fuel Prices — Azure](./03-anp-fuel-prices-azure/)           | ADLS Gen2    | Synapse Serverless        | < US$ 0,10          |
| 04 | _Em planejamento — orquestração agendada_                        | _idem_       | _idem + scheduler_        | _idem_              |
| 05 | _Em planejamento — Lakehouse Bronze/Silver/Gold com PySpark_     | _idem_       | _Delta Lake_              | _maior_             |

## Estrutura do repositório

```
projetos-engineer-git/
├── README.md                          # você está aqui
├── HANDOFF.md                         # checklist de ações que dependem do usuário
├── .gitignore
├── shared/                            # código Python comum aos 3 projetos
│   ├── ingest_anp.py
│   ├── requirements.txt
│   ├── config.example.yaml
│   └── sample/anp_sample.csv
├── 01-anp-fuel-prices-aws/
│   ├── README.md
│   ├── docs/                          # arquitetura + post LinkedIn
│   ├── terraform/
│   └── sql/
├── 02-anp-fuel-prices-gcp/            # mesma estrutura
└── 03-anp-fuel-prices-azure/          # mesma estrutura
```

## Por que três projetos separados (e não um multi-cloud)

Cada cloud merece sua própria narrativa de post. Um projeto = um post = um foco. O comparativo entre as três entra como **bônus do post de quinta**, mas o leitor que clicar em qualquer projeto encontra um README independente, executável, sem navegar entre pastas multi-cloud.

## Como começar

1. Leia [HANDOFF.md](./HANDOFF.md) para o checklist exato do que precisa ser feito.
2. Cada projeto tem seu próprio README com pré-requisitos e passo a passo.
3. O script Python `shared/ingest_anp.py` é único e roteado por flag (`--target {aws,azure,gcp}`).

## Sobre

Autor: Ildean — engenheiro de dados.
Contato: [LinkedIn](https://www.linkedin.com/) · ildeanmaster@gmail.com
