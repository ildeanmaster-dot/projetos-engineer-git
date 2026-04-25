# Esteira de Projetos — Engenharia de Dados Multi-cloud

Repositório público de portfólio em Engenharia de Dados, com projetos práticos desenvolvidos em paralelo nas três principais clouds: **AWS**, **Azure** e **GCP**.

Cada projeto é publicado no GitHub e acompanhado de um post no LinkedIn com infográfico de arquitetura.

## Cadência de publicação

3 posts por semana — terça, quarta e quinta, entre 10h e 14h (horário da audiência BR).

| Dia       | Tema                                  |
|-----------|---------------------------------------|
| Terça     | Implementação em **AWS**              |
| Quarta    | Implementação em **GCP**              |
| Quinta    | Implementação em **Azure** + comparativo multi-cloud |

## Projetos

| #  | Projeto                                                                                  | Stack principal                                              | Status        |
|----|------------------------------------------------------------------------------------------|--------------------------------------------------------------|---------------|
| 01 | [ANP — Preços de Combustíveis Multi-cloud](./01-anp-fuel-prices-multicloud/)             | Python · S3/Blob/GCS · Athena/Synapse Serverless/BigQuery · Terraform | Em desenvolvimento |
| 02 | _A definir — orquestração + CI/CD_                                                       | _Airflow ou nativos da cloud · GitHub Actions_              | Planejado     |
| 03 | _A definir — Lakehouse Bronze/Silver/Gold_                                               | _PySpark · Delta Lake · Databricks_                          | Planejado     |

## Estrutura de cada projeto

```
NN-nome-projeto/
├── README.md            # arquitetura + instruções multi-cloud
├── docs/                # diagrama, post LinkedIn
├── shared/              # código Python comum às 3 clouds
├── aws/                 # IaC + SQL específicos da AWS
├── azure/               # IaC + SQL específicos do Azure
└── gcp/                 # IaC + SQL específicos do GCP
```

## Sobre

Autor: Ildean — engenheiro de dados.
Contato profissional: [LinkedIn](https://www.linkedin.com/) · ildeanmaster@gmail.com
