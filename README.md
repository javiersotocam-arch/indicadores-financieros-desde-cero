# Indicadores Financieros desde Cero

Construcción de un pipeline completo de indicadores financieros a partir de tres estados contables crudos (balance, cuenta de resultados y flujo de caja), con SQL avanzado, percentiles calculados manualmente en MySQL y un pipeline equivalente en Python que termina en una ficha financiera en Excel.

## Contexto de negocio

Comparar la salud financiera de distintas empresas requiere algo más que mirar cifras sueltas: hace falta construir ratios estandarizados (liquidez, rentabilidad, solvencia, calidad del beneficio) a partir de datos contables brutos, y hacerlo de forma que el pipeline sea repetible año tras año y empresa tras empresa, no un cálculo manual puntual.

## Resultados

- **Datos**: 4.422 empresas cotizadas y 17.511 cierres anuales con los 3 estados contables disponibles ([Financial Data of 4400+ Public Companies](https://www.kaggle.com/datasets/qks1lver/financial-data-of-4400-public-companies), Kaggle).
- **Patrimonio neto negativo**: el 8,1 % de los cierres; en ellos el ROE no es interpretable y se marca con un flag.
- **Valores extremos**: la media de ratios como el ROE no sirve sin tratarlos (el ROE medio de 2018 sale un 46.810 %); la mediana sí. Winsorizar ayuda, pero no basta cuando hay muchos extremos (el margen neto medio winsorizado sale −190 %).
- **Calidad del dato**: 101 cierres duplicados en 27 tickers (por ejemplo GOOG y GOOGL, la misma empresa) y celdas vacías que, al importarse a MySQL, se convertían en ceros.

## Qué hace este proyecto

- **Modelado de la base de datos** en MySQL: tres tablas (`balance_sheet`, `income_statement`, `cash_flow`) con claves únicas por empresa-año e índices para las consultas más frecuentes.
- **Pipeline de construcción de indicadores** directamente en SQL, mediante una vista (`v_indicadores_financieros`) que calcula 4 bloques de ratios a partir del join de las tres tablas:
  - **Liquidez**: ratio de liquidez, prueba ácida
  - **Rentabilidad**: ROE, ROA, margen neto, margen operativo (con flag de patrimonio negativo, que invalida la lectura del ROE)
  - **Solvencia**: deuda sobre patrimonio, ratio de endeudamiento, cobertura de intereses
  - **Calidad del beneficio**: flujo de caja sobre beneficio neto, flujo de caja libre
- **Tratamiento de valores extremos sin alterar los datos**: en vez de recortar o eliminar los valores atípicos, se calcula el percentil 1 % y 99 % de cada ratio **a mano** (MySQL no tiene función `PERCENTILE_CONT` nativa, así que se resuelve con `ROW_NUMBER()` sobre los valores ordenados) y se marca cada fila con un flag booleano si cae fuera de ese rango, dejando la decisión de excluirlos o no en manos de quien analice los datos después.
- **Análisis exploratorio en SQL**: volumetría por tabla, empresas con histórico incompleto, crecimiento interanual de ingresos con `LAG() OVER (PARTITION BY ...)`, evolución de la rentabilidad por año y prevalencia de patrimonio neto negativo.
- **Pipeline en Python**: los mismos indicadores con pandas, la mediana para la evolución anual (y una versión winsorizada para el gráfico de dispersión), la ficha financiera por empresa y su exportación a Excel con gráficos nativos.

## Un detalle técnico destacado

MySQL no incluye una función de percentil nativa (a diferencia de PostgreSQL o motores analíticos), así que el cálculo se construye combinando `ROW_NUMBER()` sobre los valores ordenados de cada ratio con el conteo total de filas, para localizar manualmente la posición exacta del percentil 1 % y 99 %: la misma lógica que en Python resolvería `.quantile()` en una sola línea, aquí implementada explícitamente en SQL puro.

## Revisión y correcciones (octubre 2026)

La parte de Python se revisó a fondo y se reunió en un único notebook (antes eran 9 archivos, y el notebook del repositorio importaba un módulo que no estaba subido, así que no se podía ejecutar). Las correcciones más importantes:

- **Cierres duplicados**: 101 cierres repetidos en 27 tickers (GOOG y GOOGL salían dos veces en los rankings); se detectan con un auto-join y se excluyen con `NOT EXISTS`.
- **Vacíos frente a ceros**: al importar los CSV a MySQL, las celdas vacías se convertían en 0 e inflaban 2.245 flujos de caja libre.
- **Infinitos y percentiles**: los extremos se marcaban antes de quitar las divisiones por cero; ahora una división segura deja vacío lo no calculable.
- **Medias engañosas**: el ROE medio de 2018 (46.810 %) y un margen neto medio de −190 % en el gráfico de evolución; ahora se usa la mediana.
- **Seguridad y portabilidad**: la contraseña de MySQL ya no está en el código y las rutas son relativas.

Los scripts SQL también se corrigieron y se ejecutaron enteros contra los datos reales:

- **No encajaban entre sí**: la vista usaba nombres en inglés y el script de valores extremos esperaba nombres en español y un `rename_columns_es.sql` que no estaba en el repositorio. Ahora el script está incluido y toda la cadena usa los mismos nombres que el notebook.
- **Carga con vacíos como NULL**: `schema_mysql.sql` carga los CSV con `LOAD DATA` y `NULLIF(@columna, '')`, en vez del asistente de importación de Workbench, que convertía los vacíos en 0.
- **Duplicados y ranking por año**: la vista incluye la columna `cierre_duplicado`, y el top 10 por ingresos filtra por año de cierre y excluye duplicados con `NOT EXISTS`.
- **Márgenes con todos los decimales**: beneficio e ingresos son enteros y MySQL redondeaba su división a 4 decimales.
- Los resultados coinciden con los de Python: 17.511 cierres, 1.410 con patrimonio negativo y 101 duplicados. La única diferencia es mínima: 347 cierres con ROE extremo frente a 348, porque el percentil en SQL toma la fila más cercana y pandas interpola.

## Herramientas

- **MySQL** (MySQL Workbench): modelado, vistas, window functions
- **Python** (pandas, SQLAlchemy, matplotlib, openpyxl): pipeline de indicadores, exploración y exportación a Excel

## Estructura del repositorio

- `schema_mysql.sql`: creación de la base de datos y las tablas, y carga de los CSV
- `rename_columns_es.sql`: renombra al español las columnas que usa el proyecto
- `queries_analisis.sql`: exploración y calidad del dato en SQL, y vista `v_indicadores_financieros`
- `flags_valores_extremos.sql`: percentiles manuales y flags de valores extremos
- `indicadores_financieros_python_explicado.ipynb`: el pipeline completo en Python, explicado paso a paso
- `indicadores_financieros_python_explicado.pdf`: el mismo notebook en PDF

## Cómo ejecutarlo

**SQL (MySQL Workbench)**

Requiere MySQL 8.0 o superior. Ejecuta los scripts en este orden:

1. `schema_mysql.sql`: crea la base de datos y carga los 3 CSV. Antes, cambia `/ruta/a/` por la carpeta donde tengas los CSV y activa la carga local (instrucciones dentro del script).
2. `rename_columns_es.sql`: pasa al español los nombres de las columnas (solo una vez).
3. `queries_analisis.sql`: exploración y creación de la vista `v_indicadores_financieros`.
4. `flags_valores_extremos.sql`: percentiles y vista `v_indicadores_con_flags`.

**Python**

1. Descarga los 3 CSV anuales del dataset de Kaggle (`balanceSheetHistory_annually.csv`, `incomeStatementHistory_annually.csv`, `cashflowStatement_annually.csv`) en una carpeta `datos/` junto al notebook.
2. Abre el notebook y ejecútalo de arriba abajo. Por defecto crea una base SQLite a partir de los CSV; para usar MySQL, cambia `FUENTE = 'mysql'` (la contraseña se pide al ejecutar).
3. La ficha financiera se guarda en `output/ficha_financiera_empresas.xlsx`.

## Autor

Javier Sotoca — [portfolio completo](https://sites.google.com/view/javiersotoca/home)
