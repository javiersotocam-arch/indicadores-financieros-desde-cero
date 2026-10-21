-- ============================================================================
-- queries_analisis.sql
-- Exploración, calidad de datos y vista de indicadores en MySQL.
--
-- Requiere haber ejecutado antes:
--   1) schema_mysql.sql (tablas + carga de los CSV con vacíos como NULL)
--   2) rename_columns_es.sql (columnas en español)
-- Requiere MySQL 8.0+ (funciones de ventana).
-- ============================================================================

USE financial_data;

-- ----------------------------------------------------------------------------
-- 1. Volumetría por tabla
--    Resultado: 17.511 filas y 4.422 empresas en cada tabla (jul 2012 - may 2020)
-- ----------------------------------------------------------------------------
SELECT
    'balance_sheet' AS tabla, COUNT(*) AS filas, COUNT(DISTINCT ticker) AS empresas,
    MIN(fecha_cierre) AS fecha_min, MAX(fecha_cierre) AS fecha_max
FROM balance_sheet
UNION ALL
SELECT 'income_statement', COUNT(*), COUNT(DISTINCT ticker), MIN(fecha_cierre), MAX(fecha_cierre)
FROM income_statement
UNION ALL
SELECT 'cash_flow', COUNT(*), COUNT(DISTINCT ticker), MIN(fecha_cierre), MAX(fecha_cierre)
FROM cash_flow;


-- ----------------------------------------------------------------------------
-- 2. Empresas con histórico incompleto (menos de 3 cierres)
--    Resultado: 29 empresas
-- ----------------------------------------------------------------------------
SELECT ticker, COUNT(DISTINCT fecha_cierre) AS anios_disponibles
FROM balance_sheet
GROUP BY ticker
HAVING COUNT(DISTINCT fecha_cierre) < 3
ORDER BY anios_disponibles, ticker;


-- ----------------------------------------------------------------------------
-- 3. Vacíos frente a ceros
--    Un vacío (NULL) es "no informado"; un 0 es un cero real. Si el CapEx
--    sale con muchos ceros y ningún vacío, los datos se importaron con el
--    Table Data Import Wizard y hay que volver a cargarlos (schema_mysql.sql).
--    Resultado: CapEx 2.245 vacíos y 0 ceros; ingresos 0 vacíos y 983 ceros
--    (empresas que todavía no venden).
-- ----------------------------------------------------------------------------
SELECT 'inversion_capex' AS columna, SUM(inversion_capex IS NULL) AS vacios, SUM(inversion_capex = 0) AS ceros
FROM cash_flow
UNION ALL
SELECT 'flujo_caja_operativo', SUM(flujo_caja_operativo IS NULL), SUM(flujo_caja_operativo = 0)
FROM cash_flow
UNION ALL
SELECT 'gastos_financieros', SUM(gastos_financieros IS NULL), SUM(gastos_financieros = 0)
FROM income_statement
UNION ALL
SELECT 'ingresos_totales', SUM(ingresos_totales IS NULL), SUM(ingresos_totales = 0)
FROM income_statement;


-- ----------------------------------------------------------------------------
-- 4. Cierres duplicados: tickers distintos con exactamente las mismas cifras
--    Auto-join de la tabla consigo misma. a.ticker < b.ticker evita comparar
--    un ticker consigo mismo y que cada pareja salga dos veces.
--    Resultado: 109 parejas (101 cierres de 27 tickers). Son varias clases de
--    acciones de una misma empresa (GOOG/GOOGL, FOX/FOXA...), cambios de
--    ticker (SPAR/SHYF) o errores del dataset (CHK/VEON en 2017).
-- ----------------------------------------------------------------------------
SELECT a.ticker AS ticker_1, b.ticker AS ticker_2, a.fecha_cierre, a.ingresos_totales
FROM income_statement a
INNER JOIN income_statement b
    ON  a.fecha_cierre = b.fecha_cierre
    AND a.ingresos_totales = b.ingresos_totales
    AND a.beneficio_neto = b.beneficio_neto
    AND a.ticker < b.ticker
WHERE a.ingresos_totales > 0
ORDER BY a.ticker, a.fecha_cierre;


-- ----------------------------------------------------------------------------
-- 5. Top 10 empresas por ingresos con cierre en 2019, sin duplicados
--    Se filtra por AÑO de cierre (no por '2019-12-31'), para no dejar fuera
--    a las empresas cuyo ejercicio no termina en diciembre (Walmart, Apple...).
--    NOT EXISTS excluye el cierre si otro ticker anterior tiene las mismas cifras.
--    Resultado: WMT, AMZN, BP, AAPL, CVS, XOM, UNH, MCK, T, ABC
-- ----------------------------------------------------------------------------
SELECT a.ticker, a.fecha_cierre, a.ingresos_totales
FROM income_statement a
WHERE YEAR(a.fecha_cierre) = 2019
  AND NOT EXISTS (
      SELECT 1 FROM income_statement b
      WHERE b.fecha_cierre = a.fecha_cierre
        AND b.ingresos_totales = a.ingresos_totales
        AND b.beneficio_neto = a.beneficio_neto
        AND b.ticker < a.ticker)
ORDER BY a.ingresos_totales DESC
LIMIT 10;


-- ----------------------------------------------------------------------------
-- 6. Crecimiento interanual de ingresos (window function LAG)
--    PARTITION BY ticker: cada empresa se compara solo con su propio histórico.
--    NULLIF evita dividir entre 0 cuando los ingresos del año anterior son 0.
--    Resultado: Amazon +30,8 % en 2017 y +30,9 % en 2018.
-- ----------------------------------------------------------------------------
SELECT
    ticker,
    fecha_cierre,
    ingresos_totales,
    LAG(ingresos_totales) OVER (PARTITION BY ticker ORDER BY fecha_cierre) AS ingresos_anio_anterior,
    ROUND(
        (ingresos_totales - LAG(ingresos_totales) OVER (PARTITION BY ticker ORDER BY fecha_cierre)) * 100.0
        / NULLIF(LAG(ingresos_totales) OVER (PARTITION BY ticker ORDER BY fecha_cierre), 0),
        2
    ) AS crecimiento_pct
FROM income_statement
WHERE ticker IN ('AAPL', 'MSFT', 'AMZN', 'GOOG')
ORDER BY ticker, fecha_cierre;


-- ----------------------------------------------------------------------------
-- 7. Patrimonio neto negativo por año
--    Se cuentan CIERRES (empresa-año) y EMPRESAS por separado: algunas
--    empresas cambian de fecha de cierre y tienen dos cierres en el mismo año.
--    Resultado: 9,9 % (2016), 9,4 % (2017), 7,4 % (2018), 6,0 % (2019)
-- ----------------------------------------------------------------------------
SELECT
    YEAR(fecha_cierre) AS anio,
    COUNT(*) AS cierres,
    COUNT(DISTINCT ticker) AS empresas,
    SUM(CASE WHEN patrimonio_neto_total < 0 THEN 1 ELSE 0 END) AS con_patrimonio_negativo,
    ROUND(100.0 * SUM(CASE WHEN patrimonio_neto_total < 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct
FROM balance_sheet
WHERE YEAR(fecha_cierre) BETWEEN 2016 AND 2019
GROUP BY YEAR(fecha_cierre)
ORDER BY anio;


-- ----------------------------------------------------------------------------
-- 8. Rentabilidad media por año: por qué la media no sirve
--    Basta una empresa con un patrimonio minúsculo para que su ROE sea
--    gigantesco y arrastre la media: en 2018 el ROE medio sale 468,1 (un
--    46.810 %), mientras que la mediana es del 6,4 %. Para los agregados se
--    usa la mediana o los flags de valores extremos (flags_valores_extremos.sql).
-- ----------------------------------------------------------------------------
SELECT
    YEAR(b.fecha_cierre) AS anio,
    COUNT(*) AS cierres,
    ROUND(AVG(i.beneficio_neto / b.patrimonio_neto_total), 4) AS roe_medio,
    ROUND(AVG(i.beneficio_neto / b.activo_total), 4) AS roa_medio
FROM balance_sheet b
INNER JOIN income_statement i ON b.ticker = i.ticker AND b.fecha_cierre = i.fecha_cierre
WHERE b.patrimonio_neto_total > 0
  AND b.activo_total > 0
  AND YEAR(b.fecha_cierre) BETWEEN 2016 AND 2019
GROUP BY YEAR(b.fecha_cierre)
ORDER BY anio;


-- ----------------------------------------------------------------------------
-- 9. Vista reutilizable: ficha de indicadores calculada directamente en SQL
--    (equivalente a construir_indicadores() del notebook de Python)
--    - NULLIF(x, 0): una división entre 0 da NULL, nunca un error.
--    - Los gastos financieros vienen en negativo: la cobertura usa ABS().
--    - El CapEx viene en negativo: el flujo de caja libre es operativo + CapEx.
--    - El ROE con patrimonio negativo no se borra: se marca con un flag.
--    - cierre_duplicado marca los cierres repetidos de la consulta 4, para
--      poder excluirlos de los rankings.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_indicadores_financieros AS
SELECT
    b.ticker,
    b.fecha_cierre,
    YEAR(b.fecha_cierre) AS anio,
    i.ingresos_totales,
    i.beneficio_neto,
    b.activo_total,
    -- Liquidez
    b.activo_corriente_total / NULLIF(b.pasivo_corriente_total, 0) AS ratio_liquidez,
    (b.activo_corriente_total - IFNULL(b.inventario, 0)) / NULLIF(b.pasivo_corriente_total, 0) AS ratio_prueba_acida,
    -- Rentabilidad
    i.beneficio_neto / NULLIF(b.patrimonio_neto_total, 0) AS roe,
    (b.patrimonio_neto_total < 0) AS patrimonio_negativo,
    i.beneficio_neto / NULLIF(b.activo_total, 0) AS roa,
    -- 1e0 * fuerza una división con decimales completos: beneficio e ingresos son
    -- enteros (BIGINT) y MySQL redondearía el resultado a 4 decimales
    1e0 * i.beneficio_neto / NULLIF(i.ingresos_totales, 0) AS margen_neto,
    1e0 * i.beneficio_operativo / NULLIF(i.ingresos_totales, 0) AS margen_operativo,
    -- Solvencia
    b.pasivo_total / NULLIF(b.patrimonio_neto_total, 0) AS deuda_sobre_patrimonio,
    b.pasivo_total / NULLIF(b.activo_total, 0) AS ratio_endeudamiento,
    i.ebit / NULLIF(ABS(i.gastos_financieros), 0) AS cobertura_intereses,
    -- Calidad del beneficio
    c.flujo_caja_operativo / NULLIF(i.beneficio_neto, 0) AS flujo_caja_sobre_beneficio_neto,
    c.flujo_caja_operativo + c.inversion_capex AS flujo_caja_libre,
    -- Calidad del dato
    EXISTS (
        SELECT 1 FROM income_statement d
        WHERE d.fecha_cierre = i.fecha_cierre
          AND d.ingresos_totales = i.ingresos_totales
          AND d.beneficio_neto = i.beneficio_neto
          AND d.ticker < i.ticker
          AND i.ingresos_totales > 0) AS cierre_duplicado
FROM balance_sheet b
INNER JOIN income_statement i ON b.ticker = i.ticker AND b.fecha_cierre = i.fecha_cierre
INNER JOIN cash_flow c ON b.ticker = c.ticker AND b.fecha_cierre = c.fecha_cierre;

-- Comprobación: 17.511 cierres, 1.410 con patrimonio negativo (8,1 %), 101 duplicados
SELECT COUNT(*) AS cierres,
       SUM(patrimonio_negativo) AS con_patrimonio_negativo,
       SUM(cierre_duplicado) AS cierres_duplicados
FROM v_indicadores_financieros;

-- Uso: top 15 por ROE en 2019, sin patrimonio negativo ni duplicados.
-- Los primeros puestos son valores extremos (NRT, con un ROE de 62,9, es un
-- 6.294 %): flags_valores_extremos.sql los marca para poder excluirlos.
SELECT ticker, fecha_cierre, ROUND(roe, 3) AS roe
FROM v_indicadores_financieros
WHERE anio = 2019 AND patrimonio_negativo = 0 AND cierre_duplicado = 0
ORDER BY roe DESC
LIMIT 15;
