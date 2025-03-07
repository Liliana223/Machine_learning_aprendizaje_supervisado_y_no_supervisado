# Carga de librerias 
library(readr) 
library(dplyr)
library(tidyr)
library(datasets)

# Depurado del conjunto de datos: 

data(iris)
data_to_clean = select(iris, -Species)

# Verificar las dimensiones del conjunto de datos
print(paste("El conjunto de datos tiene", nrow(data_to_clean), "filas y", ncol(data_to_clean), "columnas."))

##########################################
# Identificación de Valores no Numéricos #
##########################################

# Identificar qué columnas no son numéricas
# Usamos sapply para aplicar una función a cada columna y luego identificamos las que no son numéricas
non_numeric_columns <- sapply(data_to_clean, function(x) !is.numeric(x))

# Imprimir los nombres de las columnas no numéricas
non_numeric_names <- names(data_to_clean)[non_numeric_columns]
print(non_numeric_names)

# Verificar los datos almacenados como texto
data_to_clean$CFB

# Visualizar el tipo de cada una de las columnas no numéricas
non_numeric_types <- sapply(data_to_clean[non_numeric_columns], class)
print(non_numeric_types)

# Transformar números almacenados como texto a datos numéricos
# asumiendo que se necesita revisar todas las columnas y convertir donde sea aplicable
data_to_clean <- data_to_clean %>%
  mutate(across(where(is.character), ~parse_number(.))) # Convierte texto a numéricos

# Verificar los cambios
non_numeric_columns <- sapply(data_to_clean, function(x) !is.numeric(x))
non_numeric_names <- names(data_to_clean)[non_numeric_columns]
print(non_numeric_names)

#################################
# Identificación de Datos Nulos #
#################################

# Identificar valores nulos en el conjunto de datos
# Calcular el número de valores NA por columna
na_count_per_column <- sapply(data_to_clean, function(x) sum(is.na(x)))

# Para obtener una visión más general, podemos calcular el total de NAs en todo el conjunto de datos
total_nas <- sum(na_count_per_column)
print(paste("Total de valores NA en el conjunto de datos:", total_nas))

# Para ver las filas que contienen al menos un NA, puedes usar:
rows_with_na <- which(rowSums(is.na(data_to_clean)) > 0)
print(paste("Hay", length(rows_with_na), "filas con al menos un valor NA."))

#####################################
# Identificación de Datos Infinitos #
#####################################

# Identificar valores nulos en el conjunto de datos
# Calcular el número de valores NA por columna
inf_count_per_column <- sapply(data_to_clean, function(x) sum(is.infinite(x)))

# Para obtener una visión más general, podemos calcular el total de NAs en todo el conjunto de datos
total_inf <- sum(inf_count_per_column)
print(paste("Total de valores infinitos en el conjunto de datos:", total_inf))

# Verificar los datos NA y eliminarlos
colSums(is.na(data_to_clean))
df_complete <- data_to_clean[complete.cases(data_to_clean),]
any(is.na(df_complete))

##########################
# Normalización de Datos #
##########################

# Normalizar los datos
# Escalar cada columna para que tenga media ~0 y desviación estándar ~1
normalized_data <- as.data.frame(lapply(df_complete, scale))

# Añadir de nuevo la columna "Species"
normalized_data$Species <- iris$Species

# Guardar los datos normalizados en un fichero CSV
write.csv(normalized_data, "iris.csv", row.names = FALSE)

#################################################################
# Implementación de tres métodos de aprendizaje no supervisado
#################################################################

# Cargar los paquetes necesarios MDS y para realizar PCA
library(stats)   # Para la función cmdscale (MDS)
library(ggplot2) # Para graficar
library(plotly)  # Para graficar en 3D
library(readr)   # Para leer archivos CSV

##########
### MDS###
##########

# Leer los datos
data <- read.csv("iris.csv")

# Seleccionar solo las características numéricas para el MDS
data_mds <- select(data, -Species)

# Calcular la matriz de distancias entre las muestras
dist_matrix <- dist(data_mds, method = "euclidean")

# Realizar MDS para 2 componentes
mds_2d <- cmdscale(dist_matrix, k = 3, eig = TRUE)

# Preparar los datos para graficar en 2D
data_2d <- as.data.frame(mds_2d$points)
data_2d$Species <- data$Species

# Graficar los resultados en 2D
ggplot(data_2d, aes(x = V1, y = V2, color = Species)) +
  geom_point() +
  ggtitle("MDS - 2 Componentes") +
  xlab("Componente 1") +
  ylab("Componente 2")

# Realizar MDS para 3 componentes
mds_3d <- cmdscale(dist_matrix, k = 3, eig = TRUE)

# Preparar los datos para graficar en 3D
data_3d <- as.data.frame(mds_3d$points)
data_3d$Species <- data$Species

# Usar plotly para un gráfico interactivo en 3D
fig <- plot_ly(data_3d, x = ~V1, y = ~V2, z = ~V3, color = ~Species, colors = c('#BF382A', '#0C4B8E')) %>%
  add_markers() %>%
  layout(scene = list(xaxis = list(title = 'Componente 1'),
                      yaxis = list(title = 'Componente 2'),
                      zaxis = list(title = 'Componente 3')),
         title = 'MDS - 3 Componentes')

fig

# Calculo de la varianza explicada empleando el estrés
# Fórmula del estrés: sqrt(sum((dist(originales) - dist(proyectadas))^2) / sum(dist(originales)^2))
stress_2d <- sqrt(sum((dist_matrix - dist(as.matrix(mds_2d$points)))^2) / sum(dist_matrix^2))
stress_3d <- sqrt(sum((dist_matrix - dist(as.matrix(mds_3d$points)))^2) / sum(dist_matrix^2))

# Imprimir los valores de estrés
print(paste("Estrés para 2 componentes:", stress_2d))
print(paste("Estrés para 3 componentes:", stress_3d))

# El valor de "Estrés" oscila entre 0 a 1. En términos simples, el estrés cuantifica cuán bien la configuración en el espacio reducido 
# preserva las distancias originales. Un menor valor de estrés indica que la reducción de dimensionalidad ha logrado representar las 
# distancias originales con mayor precisión.

## CONCLUSION: 

# Trabajar con tres dimensiones nos proporcionaría una mayor certidumbre en los datos, ya que explicaría una mayor cantidad de la 
# varianza en los mismos.

##########
### PCA###
##########


# Seleccionar solo las características numéricas para el PCA
data_pca <- select(data, -Species)

# Realizar PCA
pca_result <- prcomp(data_pca, scale. = FALSE, center = TRUE)

# Ver la varianza explicada por cada componente principal
print(summary(pca_result))

# Con PCA tendríamos representado alrededor del 99% de los datos con tres componentes principales.

# PCA para 2 componentes principales
# Preparar los datos para graficar
data_2d1 <- data.frame(pca_result$x[,1:2])
data_2d1$Species <- data$Species

# Graficar los resultados en 2D
ggplot(data_2d1, aes(x = PC1, y = PC2, color = Species)) +
  geom_point() +
  ggtitle("PCA - 2 Componentes Principales") +
  xlab("Primer Componente Principal") +
  ylab("Segundo Componente Principal")

# PCA para 3 componentes principales
# Preparar los datos para graficar
data_3d1 <- data.frame(pca_result$x[,1:3])
data_3d1$Species <- data$Species

# Usar plotly para un gráfico interactivo en 3D
fig <- plot_ly(data_3d1, x = ~PC1, y = ~PC2, z = ~PC3, color = ~Species, colors = c('#BF382A', '#0C4B8E')) %>%
  add_markers() %>%
  layout(scene = list(xaxis = list(title = 'PC1'),
                      yaxis = list(title = 'PC2'),
                      zaxis = list(title = 'PC3')),
         title = 'PCA - 3 Componentes Principales')

# Mostrar el gráfico
fig

## CONCLUSION: 

# Trabajar con tres dimensiones nos proporcionaría una mayor certidumbre en los datos, ya que explicaría una mayor cantidad de la 
# varianza en los mismos.

#############
### ISOMAP###
#############

# Cargar los paquetes necesarios
library(vegan) # Para isomap

# Seleccionar solo las características numéricas para Isomap
data_iso <- select(data, -Species)

# Calcular la matriz de distancias entre las muestras
dist_matrix <- dist(data_iso, method = "euclidean")

# Realizar Isomap para 2 y 3 componentes
iso_2d <- isomap(dist_matrix, k = 10, ndim = 2)  # Podemos usar distintos valores de k vecinos más cercanos
iso_3d <- isomap(dist_matrix, k = 10, ndim = 3)

# Calcular estrés basado en la discrepancia de las distancias
# Estrés se calcula como: sqrt(sum((distancias originales - distancias en baja dimensión)^2) / sum(distancias originales^2))
# Valores Típicos y Guías Generales para el Estrés
# 0% a 0.05% (0 a 0.05): Estrés extremadamente bajo, excelente preservación de distancias.
# 0.05% a 0.1% (0.05 a 0.1): Estrés muy bajo, muy buena representación de las distancias.
# 0.1% a 0.2% (0.1 a 0.2): Estrés bajo, buena representación.
# 0.2% a 0.4% (0.2 a 0.4): Estrés moderado, representación aceptable.
# Mayor que 0.4% (>0.4): Estrés alto, la preservación de distancias puede ser inadecuada para algunas aplicaciones.
stress_2d <- sqrt(sum((dist_matrix - dist(as.matrix(iso_2d$points)))^2) / sum(dist_matrix^2))
stress_3d <- sqrt(sum((dist_matrix - dist(as.matrix(iso_3d$points)))^2) / sum(dist_matrix^2))

print(paste("Estrés para 2 dimensiones:", stress_2d))
print(paste("Estrés para 3 dimensiones:", stress_3d))

# Preparar datos para graficar
data_2d2 <- as.data.frame(iso_2d$points)
data_2d2$Species <- data$Species

data_3d2 <- as.data.frame(iso_3d$points)
data_3d2$Species <- data$Species

# Graficar Isomap en 2D
ggplot(data_2d2, aes(x = Dim1, y = Dim2, color = Species)) +
  geom_point() +
  ggtitle("Isomap - 2 Dimensiones") +
  xlab("Componente 1") +
  ylab("Componente 2")

# Usar plotly para un gráfico interactivo en 3D
fig <- plot_ly(data_3d2, x = ~Dim1, y = ~Dim2, z = ~Dim3, color = ~Species, colors = c('#BF382A', '#0C4B8E')) %>%
  add_markers() %>%
  layout(scene = list(xaxis = list(title = 'Componente 1'),
                      yaxis = list(title = 'Componente 2'),
                      zaxis = list(title = 'Componente 3')),
         title = 'Isomap - 3 Dimensiones')
fig

## CONCLUSION: 

# Trabajar con tres dimensiones nos proporcionaría una mayor certidumbre en los datos, ya que explicaría una mayor cantidad de la 
# varianza en los mismos.