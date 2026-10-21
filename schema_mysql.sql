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
    INDEX idx_income_date (endDate),
    INDEX idx_income_date_revenue (endDate, totalRevenue)   -- acelera la detección de cierres duplicados
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
-- IMPORTANTE: los CSV tienen muchas celdas vacías (por ejemplo, el CapEx falta
-- en 2.245 cierres). Un vacío significa "la empresa no lo informó", no "cero".
--
-- El "Table Data Import Wizard" de MySQL Workbench convierte esos vacíos en 0,
-- y entonces ratios como el flujo de caja libre salen con valores falsos. Por
-- eso se carga con LOAD DATA y NULLIF(@columna, ''): cada vacío se guarda
-- como NULL.
--
-- Antes de ejecutarlo:
--   1. Sustituye '/ruta/a/' por la carpeta donde tengas los 3 CSV de Kaggle.
--   2. Activa la carga local: en Workbench, edita la conexión -> Advanced ->
--      Others: OPT_LOCAL_INFILE=1, y ejecuta SET GLOBAL local_infile = 1;
--   3. Si tus CSV vienen de Windows con saltos de línea \r\n, cambia
--      LINES TERMINATED BY '\n' por '\r\n'.
-- ============================================================================

LOAD DATA LOCAL INFILE '/ruta/a/balanceSheetHistory_annually.csv'
INTO TABLE balance_sheet
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@stock, @endDate, @accountsPayable, @inventory, @longTermDebt, @netReceivables, @netTangibleAssets, @longTermInvestments, @totalCurrentAssets, @propertyPlantEquipment, @otherStockholderEquity, @deferredLongTermAssetCharges, @totalCurrentLiabilities, @cash, @otherAssets, @treasuryStock, @goodWill, @otherLiab, @retainedEarnings, @otherCurrentAssets, @commonStock, @totalAssets, @otherCurrentLiab, @deferredLongTermLiab, @totalStockholderEquity, @totalLiab, @capitalSurplus, @intangibleAssets, @shortTermInvestments, @shortLongTermDebt, @minorityInterest)
SET
    stock = NULLIF(@stock, ''),
    endDate = NULLIF(@endDate, ''),
    accountsPayable = NULLIF(@accountsPayable, ''),
    inventory = NULLIF(@inventory, ''),
    longTermDebt = NULLIF(@longTermDebt, ''),
    netReceivables = NULLIF(@netReceivables, ''),
    netTangibleAssets = NULLIF(@netTangibleAssets, ''),
    longTermInvestments = NULLIF(@longTermInvestments, ''),
    totalCurrentAssets = NULLIF(@totalCurrentAssets, ''),
    propertyPlantEquipment = NULLIF(@propertyPlantEquipment, ''),
    otherStockholderEquity = NULLIF(@otherStockholderEquity, ''),
    deferredLongTermAssetCharges = NULLIF(@deferredLongTermAssetCharges, ''),
    totalCurrentLiabilities = NULLIF(@totalCurrentLiabilities, ''),
    cash = NULLIF(@cash, ''),
    otherAssets = NULLIF(@otherAssets, ''),
    treasuryStock = NULLIF(@treasuryStock, ''),
    goodWill = NULLIF(@goodWill, ''),
    otherLiab = NULLIF(@otherLiab, ''),
    retainedEarnings = NULLIF(@retainedEarnings, ''),
    otherCurrentAssets = NULLIF(@otherCurrentAssets, ''),
    commonStock = NULLIF(@commonStock, ''),
    totalAssets = NULLIF(@totalAssets, ''),
    otherCurrentLiab = NULLIF(@otherCurrentLiab, ''),
    deferredLongTermLiab = NULLIF(@deferredLongTermLiab, ''),
    totalStockholderEquity = NULLIF(@totalStockholderEquity, ''),
    totalLiab = NULLIF(@totalLiab, ''),
    capitalSurplus = NULLIF(@capitalSurplus, ''),
    intangibleAssets = NULLIF(@intangibleAssets, ''),
    shortTermInvestments = NULLIF(@shortTermInvestments, ''),
    shortLongTermDebt = NULLIF(@shortLongTermDebt, ''),
    minorityInterest = NULLIF(@minorityInterest, '');

LOAD DATA LOCAL INFILE '/ruta/a/incomeStatementHistory_annually.csv'
INTO TABLE income_statement
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@stock, @endDate, @netIncomeApplicableToCommonShares, @netIncomeFromContinuingOps, @totalOtherIncomeExpenseNet, @costOfRevenue, @totalOperatingExpenses, @totalRevenue, @incomeTaxExpense, @interestExpense, @operatingIncome, @ebit, @grossProfit, @sellingGeneralAdministrative, @netIncome, @incomeBeforeTax, @researchDevelopment, @otherOperatingExpenses, @minorityInterest, @discontinuedOperations)
SET
    stock = NULLIF(@stock, ''),
    endDate = NULLIF(@endDate, ''),
    netIncomeApplicableToCommonShares = NULLIF(@netIncomeApplicableToCommonShares, ''),
    netIncomeFromContinuingOps = NULLIF(@netIncomeFromContinuingOps, ''),
    totalOtherIncomeExpenseNet = NULLIF(@totalOtherIncomeExpenseNet, ''),
    costOfRevenue = NULLIF(@costOfRevenue, ''),
    totalOperatingExpenses = NULLIF(@totalOperatingExpenses, ''),
    totalRevenue = NULLIF(@totalRevenue, ''),
    incomeTaxExpense = NULLIF(@incomeTaxExpense, ''),
    interestExpense = NULLIF(@interestExpense, ''),
    operatingIncome = NULLIF(@operatingIncome, ''),
    ebit = NULLIF(@ebit, ''),
    grossProfit = NULLIF(@grossProfit, ''),
    sellingGeneralAdministrative = NULLIF(@sellingGeneralAdministrative, ''),
    netIncome = NULLIF(@netIncome, ''),
    incomeBeforeTax = NULLIF(@incomeBeforeTax, ''),
    researchDevelopment = NULLIF(@researchDevelopment, ''),
    otherOperatingExpenses = NULLIF(@otherOperatingExpenses, ''),
    minorityInterest = NULLIF(@minorityInterest, ''),
    discontinuedOperations = NULLIF(@discontinuedOperations, '');

LOAD DATA LOCAL INFILE '/ruta/a/cashflowStatement_annually.csv'
INTO TABLE cash_flow
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@stock, @endDate, @capitalExpenditures, @changeToNetincome, @otherCashflowsFromFinancingActivities, @changeToAccountReceivables, @changeToInventory, @dividendsPaid, @otherCashflowsFromInvestingActivities, @depreciation, @totalCashFromOperatingActivities, @effectOfExchangeRate, @repurchaseOfStock, @changeInCash, @netIncome, @changeToOperatingActivities, @totalCashFromFinancingActivities, @netBorrowings, @totalCashflowsFromInvestingActivities, @changeToLiabilities, @issuanceOfStock, @investments)
SET
    stock = NULLIF(@stock, ''),
    endDate = NULLIF(@endDate, ''),
    capitalExpenditures = NULLIF(@capitalExpenditures, ''),
    changeToNetincome = NULLIF(@changeToNetincome, ''),
    otherCashflowsFromFinancingActivities = NULLIF(@otherCashflowsFromFinancingActivities, ''),
    changeToAccountReceivables = NULLIF(@changeToAccountReceivables, ''),
    changeToInventory = NULLIF(@changeToInventory, ''),
    dividendsPaid = NULLIF(@dividendsPaid, ''),
    otherCashflowsFromInvestingActivities = NULLIF(@otherCashflowsFromInvestingActivities, ''),
    depreciation = NULLIF(@depreciation, ''),
    totalCashFromOperatingActivities = NULLIF(@totalCashFromOperatingActivities, ''),
    effectOfExchangeRate = NULLIF(@effectOfExchangeRate, ''),
    repurchaseOfStock = NULLIF(@repurchaseOfStock, ''),
    changeInCash = NULLIF(@changeInCash, ''),
    netIncome = NULLIF(@netIncome, ''),
    changeToOperatingActivities = NULLIF(@changeToOperatingActivities, ''),
    totalCashFromFinancingActivities = NULLIF(@totalCashFromFinancingActivities, ''),
    netBorrowings = NULLIF(@netBorrowings, ''),
    totalCashflowsFromInvestingActivities = NULLIF(@totalCashflowsFromInvestingActivities, ''),
    changeToLiabilities = NULLIF(@changeToLiabilities, ''),
    issuanceOfStock = NULLIF(@issuanceOfStock, ''),
    investments = NULLIF(@investments, '');

-- Comprobación: el CapEx debe tener vacíos (NULL) y ningún cero
SELECT SUM(capitalExpenditures IS NULL) AS capex_vacio,
       SUM(capitalExpenditures = 0)     AS capex_cero
FROM cash_flow;

-- ============================================================================
-- VERIFICACIÓN RÁPIDA POST-CARGA
-- ============================================================================
SELECT 'balance_sheet' AS tabla, COUNT(*) AS filas, COUNT(DISTINCT stock) AS empresas FROM balance_sheet
UNION ALL
SELECT 'income_statement', COUNT(*), COUNT(DISTINCT stock) FROM income_statement
UNION ALL
SELECT 'cash_flow', COUNT(*), COUNT(DISTINCT stock) FROM cash_flow;
