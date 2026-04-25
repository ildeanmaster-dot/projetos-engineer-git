-- BigQuery — queries analíticas sobre os preços da ANP.
-- A tabela externa `anp_fuel_prices.weekly_prices_raw` foi criada via Terraform
-- com Hive partitioning (year, month) e schema fixo. Trocar `__PROJECT__` pelo
-- seu project id ou usar o dataset diretamente se já estiver no projeto correto.

-- Query 1 — preço médio do diesel por UF na partição mais recente
WITH base AS (
    SELECT
        estado_sigla,
        produto,
        PARSE_DATE('%d/%m/%Y', data_coleta)            AS dt_coleta,
        SAFE_CAST(REPLACE(valor_venda, ',', '.') AS FLOAT64) AS preco,
        year, month
    FROM `__PROJECT__.anp_fuel_prices.weekly_prices_raw`
),
latest AS (
    SELECT MAX(year) AS y FROM base
),
latest_partition AS (
    SELECT (SELECT y FROM latest) AS year,
           MAX(month) AS month
    FROM base
    WHERE year = (SELECT y FROM latest)
)
SELECT
    estado_sigla,
    ROUND(AVG(preco), 3) AS preco_medio_diesel,
    COUNT(*)             AS coletas
FROM base, latest_partition
WHERE base.year  = latest_partition.year
  AND base.month = latest_partition.month
  AND LOWER(produto) LIKE 'diesel%'
GROUP BY estado_sigla
ORDER BY preco_medio_diesel DESC;

-- Query 2 — série temporal nacional do preço médio da gasolina
SELECT
    DATE_TRUNC(PARSE_DATE('%d/%m/%Y', data_coleta), WEEK) AS semana,
    ROUND(AVG(SAFE_CAST(REPLACE(valor_venda, ',', '.') AS FLOAT64)), 3) AS preco_medio_nacional
FROM `__PROJECT__.anp_fuel_prices.weekly_prices_raw`
WHERE LOWER(produto) = 'gasolina'
GROUP BY semana
ORDER BY semana;

-- Query 3 — top 10 municípios mais caros para etanol na partição mais recente
WITH base AS (
    SELECT
        estado_sigla, municipio, produto, year, month,
        SAFE_CAST(REPLACE(valor_venda, ',', '.') AS FLOAT64) AS preco
    FROM `__PROJECT__.anp_fuel_prices.weekly_prices_raw`
),
latest AS (
    SELECT MAX(year) AS y FROM base
),
latest_partition AS (
    SELECT (SELECT y FROM latest) AS year, MAX(month) AS month
    FROM base WHERE year = (SELECT y FROM latest)
)
SELECT
    estado_sigla, municipio,
    ROUND(AVG(preco), 3) AS preco_medio_etanol,
    COUNT(*)             AS coletas
FROM base, latest_partition
WHERE base.year  = latest_partition.year
  AND base.month = latest_partition.month
  AND LOWER(produto) = 'etanol'
GROUP BY estado_sigla, municipio
HAVING coletas >= 3
ORDER BY preco_medio_etanol DESC
LIMIT 10;
