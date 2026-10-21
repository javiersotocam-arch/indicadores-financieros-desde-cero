-- ============================================================================
-- rename_columns_es.sql
-- Renombra al español todas las columnas de las 3 tablas, para que el SQL y
-- el notebook de Python (con FUENTE = 'mysql') usen los mismos nombres.
--
-- Ejecutar UNA sola vez, después de schema_mysql.sql y de la carga de datos.
-- Requiere MySQL 8.0+ (RENAME COLUMN).
-- ============================================================================

USE financial_data;

ALTER TABLE balance_sheet
    RENAME COLUMN stock TO ticker,
    RENAME COLUMN endDate TO fecha_cierre,
    RENAME COLUMN accountsPayable TO cuentas_por_pagar,
    RENAME COLUMN inventory TO inventario,
    RENAME COLUMN longTermDebt TO deuda_largo_plazo,
    RENAME COLUMN netReceivables TO cuentas_por_cobrar_netas,
    RENAME COLUMN netTangibleAssets TO activos_tangibles_netos,
    RENAME COLUMN longTermInvestments TO inversiones_largo_plazo,
    RENAME COLUMN totalCurrentAssets TO activo_corriente_total,
    RENAME COLUMN propertyPlantEquipment TO propiedad_planta_equipo,
    RENAME COLUMN otherStockholderEquity TO otro_patrimonio_neto,
    RENAME COLUMN deferredLongTermAssetCharges TO cargos_diferidos_largo_plazo,
    RENAME COLUMN totalCurrentLiabilities TO pasivo_corriente_total,
    RENAME COLUMN cash TO efectivo,
    RENAME COLUMN otherAssets TO otros_activos,
    RENAME COLUMN treasuryStock TO acciones_propias,
    RENAME COLUMN goodWill TO fondo_comercio,
    RENAME COLUMN otherLiab TO otros_pasivos,
    RENAME COLUMN retainedEarnings TO beneficios_retenidos,
    RENAME COLUMN otherCurrentAssets TO otros_activos_corrientes,
    RENAME COLUMN commonStock TO capital_social,
    RENAME COLUMN totalAssets TO activo_total,
    RENAME COLUMN otherCurrentLiab TO otros_pasivos_corrientes,
    RENAME COLUMN deferredLongTermLiab TO pasivo_diferido_largo_plazo,
    RENAME COLUMN totalStockholderEquity TO patrimonio_neto_total,
    RENAME COLUMN totalLiab TO pasivo_total,
    RENAME COLUMN capitalSurplus TO prima_emision,
    RENAME COLUMN intangibleAssets TO activos_intangibles,
    RENAME COLUMN shortTermInvestments TO inversiones_corto_plazo,
    RENAME COLUMN shortLongTermDebt TO deuda_corto_plazo,
    RENAME COLUMN minorityInterest TO interes_minoritario;

ALTER TABLE income_statement
    RENAME COLUMN stock TO ticker,
    RENAME COLUMN endDate TO fecha_cierre,
    RENAME COLUMN netIncomeApplicableToCommonShares TO beneficio_neto_atribuible_accionistas,
    RENAME COLUMN netIncomeFromContinuingOps TO beneficio_neto_operaciones_continuadas,
    RENAME COLUMN totalOtherIncomeExpenseNet TO otros_ingresos_gastos_netos,
    RENAME COLUMN costOfRevenue TO coste_ventas,
    RENAME COLUMN totalOperatingExpenses TO gastos_operativos_totales,
    RENAME COLUMN totalRevenue TO ingresos_totales,
    RENAME COLUMN incomeTaxExpense TO gasto_impuesto_beneficios,
    RENAME COLUMN interestExpense TO gastos_financieros,
    RENAME COLUMN operatingIncome TO beneficio_operativo,
    RENAME COLUMN grossProfit TO beneficio_bruto,
    RENAME COLUMN sellingGeneralAdministrative TO gastos_venta_generales_admin,
    RENAME COLUMN netIncome TO beneficio_neto,
    RENAME COLUMN incomeBeforeTax TO beneficio_antes_impuestos,
    RENAME COLUMN researchDevelopment TO gasto_id,
    RENAME COLUMN otherOperatingExpenses TO otros_gastos_operativos,
    RENAME COLUMN minorityInterest TO interes_minoritario,
    RENAME COLUMN discontinuedOperations TO operaciones_discontinuadas;

ALTER TABLE cash_flow
    RENAME COLUMN stock TO ticker,
    RENAME COLUMN endDate TO fecha_cierre,
    RENAME COLUMN capitalExpenditures TO inversion_capex,
    RENAME COLUMN changeToNetincome TO ajuste_beneficio_neto,
    RENAME COLUMN otherCashflowsFromFinancingActivities TO otros_flujos_financiacion,
    RENAME COLUMN changeToAccountReceivables TO variacion_cuentas_por_cobrar,
    RENAME COLUMN changeToInventory TO variacion_inventario,
    RENAME COLUMN dividendsPaid TO dividendos_pagados,
    RENAME COLUMN otherCashflowsFromInvestingActivities TO otros_flujos_inversion,
    RENAME COLUMN depreciation TO depreciacion,
    RENAME COLUMN totalCashFromOperatingActivities TO flujo_caja_operativo,
    RENAME COLUMN effectOfExchangeRate TO efecto_tipo_cambio,
    RENAME COLUMN repurchaseOfStock TO recompra_acciones,
    RENAME COLUMN changeInCash TO variacion_efectivo,
    RENAME COLUMN netIncome TO beneficio_neto,
    RENAME COLUMN changeToOperatingActivities TO variacion_actividades_operativas,
    RENAME COLUMN totalCashFromFinancingActivities TO flujo_caja_financiacion,
    RENAME COLUMN netBorrowings TO endeudamiento_neto,
    RENAME COLUMN totalCashflowsFromInvestingActivities TO flujo_caja_inversion,
    RENAME COLUMN changeToLiabilities TO variacion_pasivos,
    RENAME COLUMN issuanceOfStock TO emision_acciones,
    RENAME COLUMN investments TO inversiones;

-- Comprobación
SELECT ticker, fecha_cierre, ingresos_totales, beneficio_neto
FROM income_statement
WHERE ticker = 'AAPL'
ORDER BY fecha_cierre;
