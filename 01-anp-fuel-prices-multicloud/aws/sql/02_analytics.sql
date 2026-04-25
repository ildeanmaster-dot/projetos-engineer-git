-- Athena — queries analíticas sobre os preços da ANP.
-- Conversão dos campos: valor_venda chega como string com ',' decimal e
-- data_coleta como 'DD/MM/YYYY'. As CTE abaixo normalizam isso.

-- Query 1 — preço médio do diesel por UF na partição mais recente
WITH normalized AS (
    SELECT
        estado_sigla,
        produto,
        date_parse(data_coleta, '%d/%m/%Y') AS dt_coleta,
        CAST(replace(valor_venda, ',', '.') AS DOUBLE) AS preco
    FROM anp_fuel_prices.weekly_prices_raw
    WHERE year  = (SELECT MAX(year) FROM anp_fuel_prices.weekly_prices_raw)
      AND month = (SELECT MAX(month) FROM anp_fuel_prices.weekly_prices_raw
                   WHERE year = (SELECT MAX(year) FROM anp_fuel_prices.weekly_prices_raw))
)
SELECT
    estado_sigla,
    ROUND(AVG(preco), 3) AS preco_medio_diesel,
    COUNT(*)             AS coletas
FROM normalized
WHERE LOWER(produto) LIKE 'diesel%'
GROUP BY estado_sigla
ORDER BY preco_medio_diesel DESC;

-- Query 2 — série temporal nacional do preço médio da gasolina (todas as partições)
WITH normalized AS (
    SELECT
        date_parse(data_coleta, '%d/%m/%Y') AS dt_coleta,
        CAST(replace(valor_venda, ',', '.') AS DOUBLE) AS preco
    FROM anp_fuel_prices.weekly_prices_raw
    WHERE LOWER(produto) = 'gasolina'
)
SELECT
    date_trunc('week', dt_coleta) AS semana,
    ROUND(AVG(preco), 3)          AS preco_medio_nacional
FROM normalized
GROUP BY 1
ORDER BY semana;

-- Query 3 — top 10 municípios mais caros para etanol na partição mais recente
WITH normalized AS (
    SELECT
        estado_sigla,
        municipio,
        produto,
        CAST(replace(valor_venda, ',', '.') AS DOUBLE) AS preco
    FROM anp_fuel_prices.weekly_prices_raw
    WHERE year  = (SELECT MAX(year) FROM anp_fuel_prices.weekly_prices_raw)
      AND month = (SELECT MAX(month) FROM anp_fuel_prices.weekly_prices_raw
                   WHERE year = (SELECT MAX(year) FROM anp_fuel_prices.weekly_prices_raw))
)
SELECT
    estado_sigla,
    municipio,
    ROUND(AVG(preco), 3) AS preco_medio_etanol,
    COUNT(*)             AS coletas
FROM normalized
WHERE LOWER(produto) = 'etanol'
GROUP BY estado_sigla, municipio
HAVING COUNT(*) >= 3
ORDER BY preco_medio_etanol DESC
LIMIT 10;
