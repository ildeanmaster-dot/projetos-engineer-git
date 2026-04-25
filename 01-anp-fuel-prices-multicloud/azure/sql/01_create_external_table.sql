-- Synapse Serverless SQL Pool — view sobre os CSVs da ANP no ADLS Gen2.
-- Conecte-se ao endpoint <workspace>-ondemand.sql.azuresynapse.net no banco master,
-- crie um banco de trabalho e rode as DDLs abaixo.
--
-- Substitua __STORAGE_ACCOUNT__ e __CONTAINER__ pelos seus valores antes de executar.

-- Criar banco lógico (uma vez)
IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = 'anp_fuel_prices')
    CREATE DATABASE anp_fuel_prices;
GO

USE anp_fuel_prices;
GO

-- Data source apontando para o container 'raw'
IF NOT EXISTS (SELECT 1 FROM sys.external_data_sources WHERE name = 'anp_raw')
    CREATE EXTERNAL DATA SOURCE anp_raw
        WITH (LOCATION = 'https://__STORAGE_ACCOUNT__.dfs.core.windows.net/__CONTAINER__');
GO

-- View que faz schema-on-read sobre os CSVs particionados.
-- O Synapse Serverless extrai 'year' e 'month' a partir do path via filepath().
CREATE OR ALTER VIEW dbo.weekly_prices_raw AS
SELECT
    r.regiao_sigla,
    r.estado_sigla,
    r.municipio,
    r.revenda,
    r.cnpj_revenda,
    r.nome_rua,
    r.numero_rua,
    r.complemento,
    r.bairro,
    r.cep,
    r.produto,
    r.data_coleta,
    r.valor_venda,
    r.valor_compra,
    r.unidade_medida,
    r.bandeira,
    CAST(r.filepath(1) AS INT) AS year,
    CAST(r.filepath(2) AS INT) AS month
FROM OPENROWSET(
    BULK 'raw/anp/year=*/month=*/*.csv',
    DATA_SOURCE = 'anp_raw',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0',
    FIELDTERMINATOR = ';',
    FIRSTROW = 2,
    CODEPAGE = '28591'  -- ISO-8859-1 / Latin-1
) WITH (
    regiao_sigla   VARCHAR(10),
    estado_sigla   VARCHAR(5),
    municipio      VARCHAR(100),
    revenda        VARCHAR(200),
    cnpj_revenda   VARCHAR(30),
    nome_rua       VARCHAR(200),
    numero_rua     VARCHAR(20),
    complemento    VARCHAR(100),
    bairro         VARCHAR(100),
    cep            VARCHAR(15),
    produto        VARCHAR(50),
    data_coleta    VARCHAR(15),
    valor_venda    VARCHAR(20),
    valor_compra   VARCHAR(20),
    unidade_medida VARCHAR(10),
    bandeira       VARCHAR(100)
) AS r;
GO
