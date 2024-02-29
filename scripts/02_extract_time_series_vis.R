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

dates <- names(res2) |> 
  basename() |> 
  str_extract('[0-9]{4}-[0-9]{2}-[0-9]{2}')

lapply(res2,\(x) global(x,'mean',na.rm = TRUE)) -> o

bind_cols(o) |> 
  set_names(dates) |> 
  mutate(index = c('NDVI','kNDVI')) |> 
  pivot_longer(-index) |> 
  pivot_wider(names_from  ='index',values_from = 'value') |> 
  mutate(dates = ymd(dates)) |> 
  select(-name) |> 
  select(dates,NDVI,kNDVI) |> 
  write_rds(glue('data/procesada/{sitio}_ndvi_kndvi.rds'))
