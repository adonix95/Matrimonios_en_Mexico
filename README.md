# Matrimonios_en_Mexico
Procesamiento de matrimonios en México con Bases de Datos de INEGI (1993-2024) 

# Matrimonios en México (1993–2024)

Este repositorio contiene el código en **R** utilizado para procesar los microdatos
de matrimonios del INEGI y generar una base agregada con el **total de matrimonios
por entidad federativa y año (1993–2024)**.

# IMPORTANTE 
Las bases de matrimonios de INEGI se descargan directamente en 
https://www.inegi.org.mx/programas/emat/#microdatos
éstas vienen en formato .dbf (SPSS)
Para procesarlas y convertirlas en paneles de datos es importante tener todas las bases anuales que se
quieren integrar al join, dentro de una misma carpeta. Al final, se generará un panel en formato .csv
compatible con Excel, R, stata y practicamente todos los softwares.

## Contenido
- `scripts/matrimonios_total_por_entidad_1993_2024.R`  
  Script principal de procesamiento.

## Insumos
- Archivos DBF de matrimonios del INEGI (`MATRIxx.dbf`).
- Los archivos deben colocarse en una carpeta local y ajustarse la ruta en el script.

## Salida
- `matrimonios_total_por_entidad_1993_2024.csv`
- `matrimonios_total_por_entidad_1993_2024.csv.gz`

## Reproducibilidad
- R >= 4.0
- Paquetes: `foreign`, `dplyr`, `purrr`, `stringr`, `tidyr`

## Autor
Saúl Adonis Noguez  
Plataforma Demográfica
