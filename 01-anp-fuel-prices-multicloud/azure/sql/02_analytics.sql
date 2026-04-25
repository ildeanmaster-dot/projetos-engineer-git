-- Synapse Serverless SQL — queries analíticas sobre dbo.weekly_prices_raw.
-- T-SQL não tem REPLACE direto que aceite NULL; usamos TRY_CAST para tolerar valores ruins.

-- Query 1 — preço médio do diesel por UF na partição mais recente
WITH base AS (
    SELECT
        estado_sigla,
        produto,
        TRY_CAST(REPLACE(valor_venda, ',', '.') AS FLOAT) AS preco,
        year, month
    FROM dbo.weekly_prices_raw
),
latest AS (
    SELECT TOP 1 year, month FROM base
    GROUP BY year, month
    ORDER BY year DESC, month DESC
)
SELECT
    base.estado_sigla,
    ROUND(AVG(base.preco), 3) AS preco_medio_diesel,
    COUNT(*)                  AS coletas
FROM base
JOIN latest ON base.year = latest.year AND base.month = latest.month
WHERE LOWER(base.produto) LIKE 'diesel%'
GROUP BY base.estado_sigla
ORDER BY preco_medio_diesel DESC;

-- Query 2 — série temporal nacional do preço médio da gasolina
SELECT
    DATEFROMPARTS(YEAR(dt), MONTH(dt), DAY(dt) - (DATEPART(weekday, dt) - 1)) AS semana,
    ROUND(AVG(preco), 3) AS preco_medio_nacional
FROM (
    SELECT
        TRY_CONVERT(date, data_coleta, 103) AS dt,
        TRY_CAST(REPLACE(valor_venda, ',', '.') AS FLOAT) AS preco
    FROM dbo.weekly_prices_raw
    WHERE LOWER(produto) = 'gasolina'
) src
WHERE dt IS NOT NULL
GROUP BY DATEFROMPARTS(YEAR(dt), MONTH(dt), DAY(dt) - (DATEPART(weekday, dt) - 1))
ORDER BY semana;

-- Query 3 — top 10 municípios mais caros para etanol na partição mais recente
WITH base AS (
    SELECT
        estado_sigla, municipio, produto, year, month,
        TRY_CAST(REPLACE(valor_venda, ',', '.') AS FLOAT) AS preco
    FROM dbo.weekly_prices_raw
),
latest AS (
    SELECT TOP 1 year, month FROM base
    GROUP BY year, month ORDER BY year DESC, month DESC
)
SELECT TOP 10
    base.estado_sigla,
    base.municipio,
    ROUND(AVG(base.preco), 3) AS preco_medio_etanol,
    COUNT(*)                  AS coletas
FROM base
JOIN latest ON base.year = latest.year AND base.month = latest.month
WHERE LOWER(base.produto) = 'etanol'
GROUP BY base.estado_sigla, base.municipio
HAVING COUNT(*) >= 3
ORDER BY preco_medio_etanol DESC;
