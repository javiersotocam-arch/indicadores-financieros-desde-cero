-- ============================================================================
-- rename_columns_es.sql
-- Renombra al español las columnas que usa el proyecto, para que el SQL y el
-- notebook de Python (con FUENTE = 'mysql') usen los mismos nombres.
-- Solo se renombran las columnas que intervienen en los indicadores; el resto
-- conserva el nombre original del dataset.
--
-- Ejecutar UNA sola vez, después de schema_mysql.sql y de la carga de datos.
-- Requiere MySQL 8.0+ (RENAME COLUMN).
-- ============================================================================

USE financial_data;

ALTER TABLE balance_sheet
    RENAME COLUMN stock TO ticker,
    RENAME COLUMN endDate TO fecha_cierre,
    RENAME COLUMN totalCurrentAssets TO activo_corriente_total,
    RENAME COLUMN totalCurrentLiabilities TO pasivo_corriente_total,
    RENAME COLUMN totalAssets TO activo_total,
    RENAME COLUMN totalLiab TO pasivo_total,
    RENAME COLUMN totalStockholderEquity TO patrimonio_neto_total,
    RENAME COLUMN cash TO efectivo,
    RENAME COLUMN inventory TO inventario,
    RENAME COLUMN netReceivables TO cuentas_por_cobrar_netas,
    RENAME COLUMN longTermDebt TO deuda_largo_plazo,
    RENAME COLUMN accountsPayable TO cuentas_por_pagar;

ALTER TABLE income_statement
    RENAME COLUMN stock TO ticker,
    RENAME COLUMN endDate TO fecha_cierre,
    RENAME COLUMN totalRevenue TO ingresos_totales,
    RENAME COLUMN netIncome TO beneficio_neto,
    RENAME COLUMN grossProfit TO beneficio_bruto,
    RENAME COLUMN operatingIncome TO beneficio_operativo,
    RENAME COLUMN costOfRevenue TO coste_ventas,
    RENAME COLUMN interestExpense TO gastos_financieros;

ALTER TABLE cash_flow
    RENAME COLUMN stock TO ticker,
    RENAME COLUMN endDate TO fecha_cierre,
    RENAME COLUMN totalCashFromOperatingActivities TO flujo_caja_operativo,
    RENAME COLUMN capitalExpenditures TO inversion_capex,
    RENAME COLUMN dividendsPaid TO dividendos_pagados,
    RENAME COLUMN netBorrowings TO endeudamiento_neto;

-- Comprobación
SELECT ticker, fecha_cierre, ingresos_totales, beneficio_neto
FROM income_statement
WHERE ticker = 'AAPL'
ORDER BY fecha_cierre;
