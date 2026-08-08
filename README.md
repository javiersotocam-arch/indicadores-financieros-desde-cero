# Indicadores Financieros desde Cero

Construcción de un pipeline completo de indicadores financieros a partir de tres estados contables crudos (balance, cuenta de resultados y flujo de caja), con SQL avanzado y percentiles calculados manualmente en MySQL.

## Contexto de negocio

Comparar la salud financiera de distintas empresas requiere algo más que mirar cifras sueltas: hace falta construir ratios estandarizados (liquidez, rentabilidad, solvencia, calidad del beneficio) a partir de datos contables brutos, y hacerlo de forma que el pipeline sea repetible año tras año y empresa tras empresa, no un cálculo manual puntual.

## Qué hace este proyecto

- **Modelado de la base de datos** en MySQL: tres tablas (`balance_sheet`, `income_statement`, `cash_flow`) con claves únicas por empresa-año e índices para las consultas más frecuentes.
- **Pipeline de construcción de indicadores** directamente en SQL, mediante una vista (`v_indicadores_financieros`) que calcula 4 bloques de ratios a partir del join de las tres tablas:
  - **Liquidez**: ratio de liquidez, prueba ácida
  - **Rentabilidad**: ROE, ROA, margen neto, margen operativo (con flag de patrimonio negativo, que invalida la lectura del ROE)
  - **Solvencia**: deuda sobre patrimonio, ratio de endeudamiento, cobertura de intereses
  - **Calidad del beneficio**: flujo de caja sobre beneficio neto, flujo de caja libre
- **Tratamiento de valores extremos sin alterar los datos**: en vez de recortar o eliminar los valores atípicos, se calcula el percentil 1% y 99% de cada ratio **a mano** (MySQL no tiene función `PERCENTILE_CONT` nativa, así que se resuelve con `ROW_NUMBER()` sobre los valores ordenados) y se marca cada fila con un flag booleano si cae fuera de ese rango — dejando la decisión de excluirlos o no en manos de quien analice los datos después.
- **Análisis exploratorio en SQL**: volumetría por tabla, empresas con histórico incompleto, crecimiento interanual de ingresos con `LAG() OVER (PARTITION BY ...)`, evolución de la rentabilidad media por año y prevalencia de patrimonio neto negativo.

## Un detalle técnico destacado

MySQL no incluye una función de percentil nativa (a diferencia de PostgreSQL o motores analíticos), así que el cálculo se construye combinando `ROW_NUMBER()` sobre los valores ordenados de cada ratio con el conteo total de filas, para localizar manualmente la posición exacta del percentil 1% y 99% — la misma lógica que en Python resolvería `.quantile()` en una sola línea, aquí implementada explícitamente en SQL puro.

## Herramientas

- **MySQL** (MySQL Workbench) — modelado, vistas, window functions
- **Jupyter Notebook** — exploración y documentación del proceso

## Cómo ejecutarlo

1. Crea la base de datos ejecutando `schema_mysql.sql` en MySQL Workbench.
2. Carga los tres CSV de estados financieros en sus tablas correspondientes (instrucciones detalladas dentro del propio script).
3. Ejecuta `queries_analisis.sql` para crear la vista `v_indicadores_financieros` y explorar los datos.
4. Ejecuta `flags_valores_extremos.sql` para añadir los flags de valores extremos sobre la vista anterior.
5. Abre `proyecto_indicadores_financieros_mysql.ipynb` para ver el proceso completo documentado paso a paso.

## Autor

Javier Sotoca — [portfolio completo](https://sites.google.com/view/javiersotoca/home)
