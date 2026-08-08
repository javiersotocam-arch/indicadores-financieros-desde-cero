-- ============================================================================
-- queries_analisis.sql
-- Consultas de exploración y calidad de datos, listas para ejecutar en
-- MySQL Workbench sobre la base `financial_data`.
-- Equivalente en sintaxis MySQL al notebook exploracion_sql.ipynb (SQLite).
-- ============================================================================

USE financial_data;

-- ----------------------------------------------------------------------------
-- 1. Volumetría por tabla
-- ----------------------------------------------------------------------------
SELECT
    'balance_sheet' AS tabla, COUNT(*) AS filas, COUNT(DISTINCT stock) AS empresas,
    MIN(endDate) AS fecha_min, MAX(endDate) AS fecha_max
FROM balance_sheet
UNION ALL
SELECT 'income_statement', COUNT(*), COUNT(DISTINCT stock), MIN(endDate), MAX(endDate)
FROM income_statement
UNION ALL
SELECT 'cash_flow', COUNT(*), COUNT(DISTINCT stock), MIN(endDate), MAX(endDate)
FROM cash_flow;


-- ----------------------------------------------------------------------------
-- 2. Empresas con histórico incompleto (menos de 3 años de balance)
-- ----------------------------------------------------------------------------
SELECT stock, COUNT(DISTINCT endDate) AS anios_disponibles
FROM balance_sheet
GROUP BY stock
HAVING COUNT(DISTINCT endDate) < 3
ORDER BY anios_disponibles ASC;


-- ----------------------------------------------------------------------------
-- 3. El join central del pipeline (misma lógica que en Python/SQLite)
-- ----------------------------------------------------------------------------
SELECT
    b.stock, b.endDate,
    b.totalCurrentAssets, b.totalCurrentLiabilities, b.totalAssets,
    b.totalLiab, b.totalStockholderEquity,
    i.totalRevenue, i.netIncome, i.operatingIncome,
    c.totalCashFromOperatingActivities, c.capitalExpenditures
FROM balance_sheet b
INNER JOIN income_statement i ON b.stock = i.stock AND b.endDate = i.endDate
INNER JOIN cash_flow c ON b.stock = c.stock AND b.endDate = c.endDate;


-- ----------------------------------------------------------------------------
-- 4. Rentabilidad media por año (agregado en SQL, filtrando denominadores <= 0)
--    Nota: MySQL usa YEAR(fecha) en vez de strftime('%Y', fecha) de SQLite.
-- ----------------------------------------------------------------------------
SELECT
    YEAR(b.endDate) AS anio,
    COUNT(*) AS n_empresas,
    ROUND(AVG(i.netIncome / b.totalStockholderEquity), 4) AS roe_medio,
    ROUND(AVG(i.netIncome / b.totalAssets), 4) AS roa_medio
FROM balance_sheet b
INNER JOIN income_statement i ON b.stock = i.stock AND b.endDate = i.endDate
WHERE b.totalStockholderEquity > 0
  AND b.totalAssets > 0
  AND YEAR(b.endDate) BETWEEN 2016 AND 2019
GROUP BY anio
ORDER BY anio;


-- ----------------------------------------------------------------------------
-- 5. Top 10 empresas por ingresos (2019)
-- ----------------------------------------------------------------------------
SELECT stock, endDate, totalRevenue
FROM income_statement
WHERE endDate = '2019-12-31'
ORDER BY totalRevenue DESC
LIMIT 10;


-- ----------------------------------------------------------------------------
-- 6. Crecimiento interanual de ingresos (window function LAG)
--    Requiere MySQL 8.0+ (window functions no existen en MySQL 5.7)
-- ----------------------------------------------------------------------------
SELECT
    stock,
    endDate,
    totalRevenue,
    LAG(totalRevenue) OVER (PARTITION BY stock ORDER BY endDate) AS ingresos_anio_anterior,
    ROUND(
        (totalRevenue - LAG(totalRevenue) OVER (PARTITION BY stock ORDER BY endDate)) * 100.0
        / NULLIF(LAG(totalRevenue) OVER (PARTITION BY stock ORDER BY endDate), 0),
        2
    ) AS crecimiento_pct
FROM income_statement
WHERE stock IN ('AAPL', 'MSFT', 'AMZN', 'GOOGL')
ORDER BY stock, endDate;


-- ----------------------------------------------------------------------------
-- 7. Empresas con patrimonio neto negativo, por año
-- ----------------------------------------------------------------------------
SELECT
    YEAR(endDate) AS anio,
    COUNT(*) AS total_empresas,
    SUM(CASE WHEN totalStockholderEquity < 0 THEN 1 ELSE 0 END) AS con_equity_negativo,
    ROUND(100.0 * SUM(CASE WHEN totalStockholderEquity < 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct
FROM balance_sheet
WHERE YEAR(endDate) BETWEEN 2016 AND 2019
GROUP BY anio
ORDER BY anio;


-- ----------------------------------------------------------------------------
-- 8. Vista reutilizable: ficha de indicadores calculada directamente en SQL
--    (equivalente a build_financial_indicators() de Python, pero como VIEW)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_indicadores_financieros AS
SELECT
    b.stock,
    b.endDate,
    YEAR(b.endDate) AS anio,
    i.totalRevenue,
    i.netIncome,
    b.totalAssets,
    -- Liquidez
    b.totalCurrentAssets / NULLIF(b.totalCurrentLiabilities, 0) AS current_ratio,
    (b.totalCurrentAssets - IFNULL(b.inventory, 0)) / NULLIF(b.totalCurrentLiabilities, 0) AS quick_ratio,
    -- Rentabilidad
    i.netIncome / NULLIF(b.totalStockholderEquity, 0) AS roe,
    (b.totalStockholderEquity < 0) AS equity_negativo,
    i.netIncome / NULLIF(b.totalAssets, 0) AS roa,
    i.netIncome / NULLIF(i.totalRevenue, 0) AS net_margin,
    i.operatingIncome / NULLIF(i.totalRevenue, 0) AS operating_margin,
    -- Solvencia
    b.totalLiab / NULLIF(b.totalStockholderEquity, 0) AS debt_to_equity,
    b.totalLiab / NULLIF(b.totalAssets, 0) AS debt_ratio,
    i.ebit / NULLIF(ABS(i.interestExpense), 0) AS interest_coverage,
    -- Calidad del beneficio
    c.totalCashFromOperatingActivities / NULLIF(i.netIncome, 0) AS cash_flow_to_net_income,
    c.totalCashFromOperatingActivities + c.capitalExpenditures AS free_cash_flow
FROM balance_sheet b
INNER JOIN income_statement i ON b.stock = i.stock AND b.endDate = i.endDate
INNER JOIN cash_flow c ON b.stock = c.stock AND b.endDate = c.endDate;

-- Uso: SELECT * FROM v_indicadores_financieros WHERE anio = 2019 ORDER BY roe DESC LIMIT 15;
