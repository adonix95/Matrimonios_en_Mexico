library(foreign)
library(dplyr)
library(purrr)
library(stringr)
library(tidyr)

ruta_base <- "C:/Users/Saul_/OneDrive/Plataforma demografica/RRSS/1.-Matrimonios publicación/bases matrimonios/"
anios_obj <- 1993:2024

# ---- Configuración: cómo tratar años sin medición HH/MM ----
# TRUE  -> completa HH y MM con 0 (recomendado para serie)
# FALSE -> deja HH y MM como NA en esos años
completar_no_medidos_con_cero <- TRUE #De esta forma, los años en que no se captaban matrimonios del mismo sexo aparecen con cero y el panel de datos queda
#con las mismas dimensiones.

# 1) Detectar archivos existentes (case-insensitive)
archivos <- list.files(
  ruta_base,
  pattern = "^matri\\d{2}\\.dbf$",
  ignore.case = TRUE,
  full.names = TRUE
)
if (length(archivos) == 0) stop("No se encontraron archivos MATRIxx.dbf en la ruta.")

yy <- as.integer(str_extract(tolower(basename(archivos)), "\\d{2}"))
anio_arch <- ifelse(yy >= 93, 1900 + yy, 2000 + yy)

tabla_arch <- tibble(archivo = archivos, ANIO = anio_arch) |>
  filter(ANIO %in% anios_obj) |>
  arrange(ANIO)

to_int <- function(x) suppressWarnings(as.integer(x))

# 2) Resumir por tipo de pareja para un año/archivo
resumir_tipo_pareja <- function(archivo, anio) {
  
  df <- read.dbf(archivo, as.is = TRUE) |> as_tibble()
  names(df) <- toupper(names(df))
  
  # Caso moderno: SEXO por contrayente
  if (all(c("SEXO_CON1","SEXO_CON2") %in% names(df))) {
    
    df |>
      transmute(
        SEXO1 = suppressWarnings(as.integer(SEXO_CON1)),
        SEXO2 = suppressWarnings(as.integer(SEXO_CON2))
      ) |>
      mutate(
        TIPO_PAREJA = case_when(
          SEXO1 == 1 & SEXO2 == 1 ~ "HH",
          SEXO1 == 2 & SEXO2 == 2 ~ "MM",
          (SEXO1 == 1 & SEXO2 == 2) | (SEXO1 == 2 & SEXO2 == 1) ~ "HM",
          TRUE ~ NA_character_
        )
      ) |>
      filter(!is.na(TIPO_PAREJA)) |>
      count(TIPO_PAREJA, name = "TOTAL_MATRIMONIOS") |>
      mutate(ANIO = anio) |>
      select(ANIO, TIPO_PAREJA, TOTAL_MATRIMONIOS)
    
    # Caso antiguo: 1993 / 2002 (EDAD_EL / EDAD_LA)
  } else if (all(c("EDAD_EL","EDAD_LA") %in% names(df))) {
    
    df |>
      summarise(TOTAL_MATRIMONIOS = n(), .groups = "drop") |>
      mutate(
        ANIO = anio,
        TIPO_PAREJA = "HM"
      ) |>
      select(ANIO, TIPO_PAREJA, TOTAL_MATRIMONIOS)
    
  } else {
    message("No reconozco columnas para tipo de pareja en: ",
            basename(archivo), " (", anio, "). Se omite.")
    return(NULL)
  }
}


# 3) Procesar archivos existentes
conteos <- map2_dfr(tabla_arch$archivo, tabla_arch$ANIO, resumir_tipo_pareja)

# 4) Completar con 3 renglones por año (HH/HM/MM) para toda la serie 1993–2024
plantilla <- expand_grid(
  ANIO = anios_obj,
  TIPO_PAREJA = c("HH","HM","MM")
)

resultado <- plantilla |>
  left_join(conteos, by = c("ANIO","TIPO_PAREJA")) |>
  arrange(ANIO, TIPO_PAREJA)

# Identificar años "no medidos" (solo aparece HM en conteos)
anios_no_medidos <- conteos |>
  group_by(ANIO) |>
  summarise(n_tipos = n_distinct(TIPO_PAREJA), .groups = "drop") |>
  filter(n_tipos == 1) |>
  pull(ANIO)

resultado <- resultado |>
  mutate(
    TOTAL_MATRIMONIOS = case_when(
      !is.na(TOTAL_MATRIMONIOS) ~ TOTAL_MATRIMONIOS,
      ANIO %in% anios_no_medidos & TIPO_PAREJA %in% c("HH","MM") ~
        if (completar_no_medidos_con_cero) 0L else NA_integer_,
      TRUE ~ 0L  # si falta porque no existió archivo de ese año, lo dejamos 0
    ),
    TIPO_PAREJA = recode(
      TIPO_PAREJA,
      "HH" = "Hombre-Hombre",
      "HM" = "Hombre-Mujer",
      "MM" = "Mujer-Mujer"
    )
  )

# 5) Exportar
salida_csv <- file.path(ruta_base, "matrimonios_total_tipo_pareja_1993_2024.csv")
write.csv(resultado, salida_csv, row.names = FALSE, fileEncoding = "UTF-8")

salida_gz <- paste0(salida_csv, ".gz")
con <- gzfile(salida_gz, "wb")
write.csv(resultado, con, row.names = FALSE, fileEncoding = "UTF-8")
close(con)

message("Listo. CSV: ", salida_csv)
message("Listo. CSV.GZ (recomendado web): ", salida_gz)

# Diagnóstico: qué archivos y años realmente procesó
print(tabla_arch)
