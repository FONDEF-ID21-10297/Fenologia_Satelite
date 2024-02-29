library(sen2rts)
library(tidyverse)
library(glue)

sitio <- 'rio_claro'
data <- read_rds(glue('data/procesada/{sitio}_ndvi_kndvi.rds')) |> 
  drop_na() 

data_ts <- s2ts(
  value = data$kNDVI,
  date = data$dates,
  id = 'La Esperanza',
  sensor = '2A',
  orbit = '022'
)

ts_smoothed <- smooth_s2ts(data_ts) 
ts_filled <- fill_s2ts(ts_smoothed) 
dt_cycles <- cut_cycles(ts_filled[2:353,]) # cut vegetation cycles
cf <- fit_curve(ts_filled[c(-1,-354),], dt_cycles) # fit double logistic curves
dt_pheno <- extract_pheno(cf) # extract phenological metrics

write_rds(dt_pheno,glue('data/procesada/{sitio}_kNDVI_pheno_metrics.rds'))

## Plot results
plot(ts_filled, pheno = dt_pheno, plot_points = TRUE)
ggsave(glue('output/phenology_{sitio}_NDVI.png'),
       width =10,heigh = 6,scale=1.2)

sen2r_ndvi_paths <- sample_paths("NDVI") # NDVI images (target product)
sen2r_scl_paths <- sample_paths("SCL")   # SCL images (quality flag)

## Extract, smooth and gap fill time series
data("sampleroi") # Sample spatial features for data extraction
ts_raw <- extract_s2ts(sen2r_ndvi_paths, sampleroi, scl_paths = sen2r_scl_paths)
