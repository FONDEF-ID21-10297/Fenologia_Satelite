library(terra)
library(sf)
library(tmap)
library(fs)
library(glue)
library(tidyverse)

sitio <- 'rio_claro'
dir <- glue('/mnt/data_procesada/data/rasters/Proyectos/FONDEF_ID21I10297/HLS_{sitio}')

files <- dir_ls(dir,regexp = 'tif$')

res <- lapply(files,\(f){
  im <- rast(f)
  ndvi <- app(im*1e-4,\(x) (x[4]-x[3])/(x[4]+x[3]))
  knr <- app(im*1e-4,\(x) exp(-(x[4]-x[3])^2/(2*0.15^2)))
  kndvi <- (1-knr)/(1+knr)
  names(ndvi) <- 'ndvi'
  names(kndvi) <- 'kndvi'
  return(list(ndvi,kndvi))
})

lapply(res,rast) -> res2

ndvi <- lapply(res2,'[[',1) |> rast()
kndvi <- lapply(res2,'[[',2) |> rast()

dates <- names(res2) |> 
  basename() |> 
  str_extract('[0-9]{4}-[0-9]{2}-[0-9]{2}')

m <- month(dates)
m[1:37] <-m[1:37] -6
m[38:73] <- m[38:73] +6

ndvi_mon <- tapp(ndvi,m, 'mean',na.rm = TRUE)
kndvi_mon <- tapp(kndvi,m, 'mean',na.rm = TRUE)

names(ndvi_mon) <- floor_date(ymd(dates),"1 month") |> unique()
names(kndvi_mon) <- floor_date(ymd(dates),"1 month") |> unique()

pol <- read_sf(glue('data/procesada/{sitio}.gpkg'),layer = 'borde_cuartel') |> st_transform(32719)

map_ndvi <- tm_shape(ndvi_mon[[1:11]]) + 
  tm_raster(style = 'cont',palette = 'RdYlGn',title = 'NDVI') +
  tm_shape(pol) +
  tm_borders() +
  tm_facets(nrow=2)

map_kndvi <- tm_shape(kndvi_mon[[1:11]]) + 
  tm_raster(style = 'cont',palette = 'RdYlGn',title = 'kNDVI') +
  tm_shape(pol) +
  tm_borders() +
  tm_facets(nrow=2)

tmap_save(map_ndvi,glue('output/mapa_ndvi_{sitio}.png'))
tmap_save(map_kndvi,glue('output/mapa_kndvi_{sitio}.png'))
