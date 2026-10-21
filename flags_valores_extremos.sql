-- ============================================================================
-- flags_valores_extremos.sql
-- Tratamiento de valores extremos directamente en SQL, sobre la vista
-- v_indicadores_financieros (equivalente a marcar_extremos() del notebook).
--
-- Requiere haber ejecutado antes:
--   1) schema_mysql.sql (tablas + carga de datos)
--   2) rename_columns_es.sql
--   3) queries_analisis.sql (crea v_indicadores_financieros)
-- ============================================================================

USE financial_data;

-- ----------------------------------------------------------------------------
-- 1. Tabla de percentiles (1% y 99%) por cada ratio
--
-- MySQL no tiene una funcion PERCENTILE_CONT nativa, asi que el percentil se
-- calcula "a mano": se ordenan los valores de cada ratio, se numeran con
-- ROW_NUMBER() y se toma la fila que cae en la posicion 1% / 99% del total.
-- Se guarda en una tabla de una sola fila para no recalcularlo en cada
-- consulta (los valores no cambian salvo que se recarguen los datos).
--
-- Se toma el valor de la fila más cercana a la posición del percentil, sin
-- interpolar entre dos filas como hace .quantile() en pandas. Por eso puede
-- haber una diferencia mínima: 347 cierres con ROE extremo aquí frente a 348
-- en Python, sobre 17.511.
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS percentiles_ratios;
CREATE TABLE percentiles_ratios AS
SELECT
    -- ratio_liquidez
    (SELECT ratio_liquidez FROM (
        SELECT ratio_liquidez, ROW_NUMBER() OVER (ORDER BY ratio_liquidez) rn, COUNT(*) OVER () cnt
        FROM v_indicadores_financieros WHERE ratio_liquidez IS NOT NULL
    ) t WHERE rn = GREATEST(1, ROUND(0.01 * cnt))) AS p1_ratio_liquidez,
    (SELECT ratio_liquidez FROM (
        SELECT ratio_liquidez, ROW_NUMBER() OVER (ORDER BY ratio_liquidez) rn, COUNT(*) OVER () cnt
        FROM v_indicadores_financieros WHERE ratio_liquidez IS NOT NULL
    ) t WHERE rn = ROUND(0.99 * cnt)) AS p99_ratio_liquidez,

    -- ratio_prueba_acida
    (SELECT ratio_prueba_acida FROM (
        SELECT ratio_prueba_acida, ROW_NUMBER() OVER (ORDER BY ratio_prueba_acida) rn, COUNT(*) OVER () cnt
        FROM v_indicadores_financieros WHERE ratio_prueba_acida IS NOT NULL
    ) t WHERE rn = GREATEST(1, ROUND(0.01 * cnt))) AS p1_ratio_prueba_acida,
    (SELECT ratio_prueba_acida FROM (
        SELECT ratio_prueba_acida, ROW_NUMBER() OVER (ORDER BY ratio_prueba_acida) rn, COUNT(*) OVER () cnt
        FROM v_indicadores_financieros WHERE ratio_prueba_acida IS NOT NULL
    ) t WHERE rn = ROUND(0.99 * cnt)) AS p99_ratio_prueba_acida,

    -- roe
    (SELECT roe FROM (
        SELECT roe, ROW_NUMBER() OVER (ORDER BY roe) rn, COUNT(*) OVER () cnt
        FROM v_indicadores_financieros WHERE roe IS NOT NULL
    ) t WHERE rn = GREATEST(1, ROUND(0.01 * cnt))) AS p1_roe,
    (SELECT roe FROM (
        SELECT roe, ROW_NUMBER() OVER (ORDER BY roe) rn, COUNT(*) OVER () cnt
        FROM v_indicadores_financieros WHERE roe IS NOT NULL
    ) t WHERE rn = ROUND(0.99 * cnt)) AS p99_roe,

    -- roa
    (SELECT roa FROM (
        SELECT roa, ROW_NUMBER() OVER (ORDER BY roa) rn, COUNT(*) OVER () cnt
        FROM v_indicadores_financieros WHERE roa IS NOT NULL
    ) t WHERE rn = GREATEST(1, ROUND(0.01 * cnt))) AS p1_roa,
    (SELECT roa FROM (
        SELECT roa, ROW_NUMBER() OVER (ORDER BY roa) rn, COUNT(*) OVER () cnt
        FROM v_indicadores_financieros WHERE roa IS NOT NULL
    ) t WHERE rn = ROUND(0.99 * cnt)) AS p99_roa,

    -- margen_neto
    (SELECT margen_neto FROM (
        SELECT margen_neto, ROW_NUMBER() OVER (ORDER BY margen_neto) rn, COUNT(*) OVER () cnt
        FROM v_indicadores_financieros WHERE margen_neto IS NOT NULL
    ) t WHERE rn = GREATEST(1, ROUND(0.01 * cnt))) AS p1_margen_neto,
    (SELECT margen_neto FROM (
        SELECT margen_neto, ROW_NUMBER() OVER (ORDER BY margen_neto) rn, COUNT(*) OVER () cnt
        FROM v_indicadores_financieros WHERE margen_neto IS NOT NULL
    ) t WHERE rn = ROUND(0.99 * cnt)) AS p99_margen_neto,

    -- margen_operativo
    (SELECT margen_operativo FROM (
        SELECT margen_operativo, ROW_NUMBER() OVER (ORDER BY margen_operativo) rn, COUNT(*) OVER () cnt
        FROM v_indicadores_financieros WHERE margen_operativo IS NOT NULL
    ) t WHERE rn = GREATEST(1, ROUND(0.01 * cnt))) AS p1_margen_operativo,
    (SELECT margen_operativo FROM (
        SELECT margen_operativo, ROW_NUMBER() OVER (ORDER BY margen_operativo) rn, COUNT(*) OVER () cnt
        FROM v_indicadores_financieros WHERE margen_operativo IS NOT NULL
    ) t WHERE rn = ROUND(0.99 * cnt)) AS p99_margen_operativo,

    -- deuda_sobre_patrimonio
    (SELECT deuda_sobre_patrimonio FROM (
        SELECT deuda_sobre_patrimonio, ROW_NUMBER() OVER (ORDER BY deuda_sobre_patrimonio) rn, COUNT(*) OVER () cnt
        FROM v_indicadores_financieros WHERE deuda_sobre_patrimonio IS NOT NULL
    ) t WHERE rn = GREATEST(1, ROUND(0.01 * cnt))) AS p1_deuda_sobre_patrimonio,
    (SELECT deuda_sobre_patrimonio FROM (
        SELECT deuda_sobre_patrimonio, ROW_NUMBER() OVER (ORDER BY deuda_sobre_patrimonio) rn, COUNT(*) OVER () cnt
        FROM v_indicadores_financieros WHERE deuda_sobre_patrimonio IS NOT NULL
    ) t WHERE rn = ROUND(0.99 * cnt)) AS p99_deuda_sobre_patrimonio,

    -- ratio_endeudamiento
    (SELECT ratio_endeudamiento FROM (
        SELECT ratio_endeudamiento, ROW_NUMBER() OVER (ORDER BY ratio_endeudamiento) rn, COUNT(*) OVER () cnt
        FROM v_indicadores_financieros WHERE ratio_endeudamiento IS NOT NULL
    ) t WHERE rn = GREATEST(1, ROUND(0.01 * cnt))) AS p1_ratio_endeudamiento,
    (SELECT ratio_endeudamiento FROM (
        SELECT ratio_endeudamiento, ROW_NUMBER() OVER (ORDER BY ratio_endeudamiento) rn, COUNT(*) OVER () cnt
        FROM v_indicadores_financieros WHERE ratio_endeudamiento IS NOT NULL
    ) t WHERE rn = ROUND(0.99 * cnt)) AS p99_ratio_endeudamiento,

    -- cobertura_intereses
    (SELECT cobertura_intereses FROM (
        SELECT cobertura_intereses, ROW_NUMBER() OVER (ORDER BY cobertura_intereses) rn, COUNT(*) OVER () cnt
        FROM v_indicadores_financieros WHERE cobertura_intereses IS NOT NULL
    ) t WHERE rn = GREATEST(1, ROUND(0.01 * cnt))) AS p1_cobertura_intereses,
    (SELECT cobertura_intereses FROM (
        SELECT cobertura_intereses, ROW_NUMBER() OVER (ORDER BY cobertura_intereses) rn, COUNT(*) OVER () cnt
        FROM v_indicadores_financieros WHERE cobertura_intereses IS NOT NULL
    ) t WHERE rn = ROUND(0.99 * cnt)) AS p99_cobertura_intereses,

    -- flujo_caja_sobre_beneficio_neto
    (SELECT flujo_caja_sobre_beneficio_neto FROM (
        SELECT flujo_caja_sobre_beneficio_neto, ROW_NUMBER() OVER (ORDER BY flujo_caja_sobre_beneficio_neto) rn, COUNT(*) OVER () cnt
        FROM v_indicadores_financieros WHERE flujo_caja_sobre_beneficio_neto IS NOT NULL
    ) t WHERE rn = GREATEST(1, ROUND(0.01 * cnt))) AS p1_flujo_caja_sobre_beneficio_neto,
    (SELECT flujo_caja_sobre_beneficio_neto FROM (
        SELECT flujo_caja_sobre_beneficio_neto, ROW_NUMBER() OVER (ORDER BY flujo_caja_sobre_beneficio_neto) rn, COUNT(*) OVER () cnt
        FROM v_indicadores_financieros WHERE flujo_caja_sobre_beneficio_neto IS NOT NULL
    ) t WHERE rn = ROUND(0.99 * cnt)) AS p99_flujo_caja_sobre_beneficio_neto;

SELECT * FROM percentiles_ratios;

-- ----------------------------------------------------------------------------
-- 2. Vista final: indicadores + flags de valores extremos
--
-- Igual que en el notebook de Python: el valor del ratio NUNCA se altera, solo se
-- marca con un flag booleano si cae fuera de [percentil 1%, percentil 99%].
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_indicadores_con_flags AS
SELECT
    v.*,
    (v.ratio_liquidez < p.p1_ratio_liquidez OR v.ratio_liquidez > p.p99_ratio_liquidez) AS flag_extremo_ratio_liquidez,
    (v.ratio_prueba_acida < p.p1_ratio_prueba_acida OR v.ratio_prueba_acida > p.p99_ratio_prueba_acida) AS flag_extremo_ratio_prueba_acida,
    (v.roe < p.p1_roe OR v.roe > p.p99_roe) AS flag_extremo_roe,
    (v.roa < p.p1_roa OR v.roa > p.p99_roa) AS flag_extremo_roa,
    (v.margen_neto < p.p1_margen_neto OR v.margen_neto > p.p99_margen_neto) AS flag_extremo_margen_neto,
    (v.margen_operativo < p.p1_margen_operativo OR v.margen_operativo > p.p99_margen_operativo) AS flag_extremo_margen_operativo,
    (v.deuda_sobre_patrimonio < p.p1_deuda_sobre_patrimonio OR v.deuda_sobre_patrimonio > p.p99_deuda_sobre_patrimonio) AS flag_extremo_deuda_sobre_patrimonio,
    (v.ratio_endeudamiento < p.p1_ratio_endeudamiento OR v.ratio_endeudamiento > p.p99_ratio_endeudamiento) AS flag_extremo_ratio_endeudamiento,
    (v.cobertura_intereses < p.p1_cobertura_intereses OR v.cobertura_intereses > p.p99_cobertura_intereses) AS flag_extremo_cobertura_intereses,
    (v.flujo_caja_sobre_beneficio_neto < p.p1_flujo_caja_sobre_beneficio_neto OR v.flujo_caja_sobre_beneficio_neto > p.p99_flujo_caja_sobre_beneficio_neto) AS flag_extremo_flujo_caja_sobre_beneficio_neto
FROM v_indicadores_financieros v
CROSS JOIN percentiles_ratios p;

-- ----------------------------------------------------------------------------
-- 3. Verificacion: mismo tipo de chequeo que hicimos en Python
-- ----------------------------------------------------------------------------
SELECT COUNT(*) AS filas_totales FROM v_indicadores_con_flags;

SELECT
    SUM(flag_extremo_roe) AS n_roe_extremo,
    ROUND(100.0 * SUM(flag_extremo_roe) / COUNT(*), 2) AS pct_roe_extremo
FROM v_indicadores_con_flags;

-- Ejemplo de uso: ficha de una empresa con sus flags
SELECT ticker, anio, roe, flag_extremo_roe, ratio_endeudamiento, flag_extremo_ratio_endeudamiento
FROM v_indicadores_con_flags
WHERE ticker = 'AAPL'
ORDER BY anio;
