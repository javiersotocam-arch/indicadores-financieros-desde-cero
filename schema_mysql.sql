-- ============================================================================
-- schema_mysql.sql
-- Esquema de la base de datos para el proyecto de indicadores financieros.
-- Diseñado para ejecutarse en MySQL Workbench.
-- ============================================================================

CREATE DATABASE IF NOT EXISTS financial_data
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE financial_data;

-- ----------------------------------------------------------------------------
-- Tabla: balance_sheet
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS balance_sheet;
CREATE TABLE balance_sheet (
    id INT AUTO_INCREMENT PRIMARY KEY,
    stock VARCHAR(10) NOT NULL,
    endDate DATE NOT NULL,
    accountsPayable DOUBLE,
    inventory DOUBLE,
    longTermDebt DOUBLE,
    netReceivables DOUBLE,
    netTangibleAssets DOUBLE,
    longTermInvestments DOUBLE,
    totalCurrentAssets DOUBLE,
    propertyPlantEquipment DOUBLE,
    otherStockholderEquity DOUBLE,
    deferredLongTermAssetCharges DOUBLE,
    totalCurrentLiabilities DOUBLE,
    cash DOUBLE,
    otherAssets DOUBLE,
    treasuryStock DOUBLE,
    goodWill DOUBLE,
    otherLiab DOUBLE,
    retainedEarnings DOUBLE,
    otherCurrentAssets DOUBLE,
    commonStock DOUBLE,
    totalAssets DOUBLE,
    otherCurrentLiab DOUBLE,
    deferredLongTermLiab DOUBLE,
    totalStockholderEquity DOUBLE,
    totalLiab DOUBLE,
    capitalSurplus DOUBLE,
    intangibleAssets DOUBLE,
    shortTermInvestments DOUBLE,
    shortLongTermDebt DOUBLE,
    minorityInterest DOUBLE,
    UNIQUE KEY uq_balance_stock_date (stock, endDate),
    INDEX idx_balance_stock (stock),
    INDEX idx_balance_date (endDate)
);

-- ----------------------------------------------------------------------------
-- Tabla: income_statement
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS income_statement;
CREATE TABLE income_statement (
    id INT AUTO_INCREMENT PRIMARY KEY,
    stock VARCHAR(10) NOT NULL,
    endDate DATE NOT NULL,
    netIncomeApplicableToCommonShares DOUBLE,
    netIncomeFromContinuingOps DOUBLE,
    totalOtherIncomeExpenseNet BIGINT,
    costOfRevenue BIGINT,
    totalOperatingExpenses BIGINT,
    totalRevenue BIGINT,
    incomeTaxExpense BIGINT,
    interestExpense DOUBLE,
    operatingIncome BIGINT,
    ebit BIGINT,
    grossProfit BIGINT,
    sellingGeneralAdministrative DOUBLE,
    netIncome BIGINT,
    incomeBeforeTax DOUBLE,
    researchDevelopment DOUBLE,
    otherOperatingExpenses DOUBLE,
    minorityInterest DOUBLE,
    discontinuedOperations DOUBLE,
    UNIQUE KEY uq_income_stock_date (stock, endDate),
    INDEX idx_income_stock (stock),
    INDEX idx_income_date (endDate)
);

-- ----------------------------------------------------------------------------
-- Tabla: cash_flow
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS cash_flow;
CREATE TABLE cash_flow (
    id INT AUTO_INCREMENT PRIMARY KEY,
    stock VARCHAR(10) NOT NULL,
    endDate DATE NOT NULL,
    capitalExpenditures DOUBLE,
    changeToNetincome DOUBLE,
    otherCashflowsFromFinancingActivities DOUBLE,
    changeToAccountReceivables DOUBLE,
    changeToInventory DOUBLE,
    dividendsPaid DOUBLE,
    otherCashflowsFromInvestingActivities DOUBLE,
    depreciation DOUBLE,
    totalCashFromOperatingActivities DOUBLE,
    effectOfExchangeRate DOUBLE,
    repurchaseOfStock DOUBLE,
    changeInCash DOUBLE,
    netIncome BIGINT,
    changeToOperatingActivities DOUBLE,
    totalCashFromFinancingActivities DOUBLE,
    netBorrowings DOUBLE,
    totalCashflowsFromInvestingActivities DOUBLE,
    changeToLiabilities BIGINT,
    issuanceOfStock DOUBLE,
    investments DOUBLE,
    UNIQUE KEY uq_cashflow_stock_date (stock, endDate),
    INDEX idx_cashflow_stock (stock),
    INDEX idx_cashflow_date (endDate)
);

-- ============================================================================
-- CARGA DE DATOS
-- ============================================================================
-- Opción recomendada en MySQL Workbench (interfaz gráfica, sin permisos especiales):
--   1. Click derecho sobre cada tabla en el panel "Schemas" -> "Table Data Import Wizard"
--   2. Selecciona el CSV correspondiente:
--        balance_sheet   <- balanceSheetHistory_annually.csv
--        income_statement <- incomeStatementHistory_annually.csv
--        cash_flow        <- cashflowStatement_annually.csv
--   3. En el wizard, mapea las columnas (deberían coincidir automáticamente por nombre)
--
-- Alternativa por comando (requiere permisos de FILE y secure_file_priv configurado),
-- ejecutar sustituyendo la ruta por la ubicación real del CSV en tu máquina:
--
-- LOAD DATA LOCAL INFILE '/ruta/a/balanceSheetHistory_annually.csv'
--     INTO TABLE balance_sheet
--     FIELDS TERMINATED BY ',' ENCLOSED BY '"'
--     LINES TERMINATED BY '\n'
--     IGNORE 1 ROWS
--     (stock, endDate, accountsPayable, inventory, longTermDebt, netReceivables,
--      netTangibleAssets, longTermInvestments, totalCurrentAssets, propertyPlantEquipment,
--      otherStockholderEquity, deferredLongTermAssetCharges, totalCurrentLiabilities, cash,
--      otherAssets, treasuryStock, goodWill, otherLiab, retainedEarnings, otherCurrentAssets,
--      commonStock, totalAssets, otherCurrentLiab, deferredLongTermLiab, totalStockholderEquity,
--      totalLiab, capitalSurplus, intangibleAssets, shortTermInvestments, shortLongTermDebt,
--      minorityInterest);

-- ============================================================================
-- VERIFICACIÓN RÁPIDA POST-CARGA
-- ============================================================================
SELECT 'balance_sheet' AS tabla, COUNT(*) AS filas, COUNT(DISTINCT stock) AS empresas FROM balance_sheet
UNION ALL
SELECT 'income_statement', COUNT(*), COUNT(DISTINCT stock) FROM income_statement
UNION ALL
SELECT 'cash_flow', COUNT(*), COUNT(DISTINCT stock) FROM cash_flow;
