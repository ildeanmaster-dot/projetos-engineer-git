-- Athena — tabela externa sobre os CSVs da ANP no S3.
-- Os arquivos da ANP usam separador ';', encoding latin-1 e decimal ','.
-- O OpenCSVSerde lida com o ';' e a primeira linha de cabeçalho via skip.header.line.count.
-- Os preços são lidos como STRING e convertidos nas queries (REPLACE da vírgula).

CREATE DATABASE IF NOT EXISTS anp_fuel_prices;

DROP TABLE IF EXISTS anp_fuel_prices.weekly_prices_raw;

CREATE EXTERNAL TABLE anp_fuel_prices.weekly_prices_raw (
    regiao_sigla      string,
    estado_sigla      string,
    municipio         string,
    revenda           string,
    cnpj_revenda      string,
    nome_rua          string,
    numero_rua        string,
    complemento       string,
    bairro            string,
    cep               string,
    produto           string,
    data_coleta       string,
    valor_venda       string,
    valor_compra      string,
    unidade_medida    string,
    bandeira          string
)
PARTITIONED BY (year int, month int)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    "separatorChar" = ";",
    "quoteChar"     = "\"",
    "escapeChar"    = "\\"
)
STORED AS TEXTFILE
LOCATION 's3://__BUCKET_NAME__/raw/anp/'
TBLPROPERTIES (
    "skip.header.line.count" = "1",
    "projection.enabled"     = "true",
    "projection.year.type"   = "integer",
    "projection.year.range"  = "2020,2030",
    "projection.month.type"  = "integer",
    "projection.month.range" = "1,12",
    "projection.month.digits"= "2",
    "storage.location.template" = "s3://__BUCKET_NAME__/raw/anp/year=${year}/month=${month}/"
);
