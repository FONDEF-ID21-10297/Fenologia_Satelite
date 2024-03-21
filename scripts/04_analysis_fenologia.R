library(sen2rts)
library(tidyverse)
library(glue)

sitio <- 'rio_claro'
data <- read_rds(glue('data/procesada/{sitio}_ndvi_kndvi.rds')) |> 
  drop_na() 

data_ts <- s2ts(
  value = data$NDVI,
  date = data$dates,
  id = sitio,
  sensor = '2A',
  orbit = '022'
)

ts_smoothed <- smooth_s2ts(data_ts) 
ts_filled <- fill_s2ts(ts_smoothed) 
dt_cycles <- cut_cycles(ts_filled[2:323,]) # cut vegetation cycles
cf <- fit_curve(ts_filled[2:323,], dt_cycles) # fit double logistic curves
dt_pheno <- extract_pheno(cf) # extract phenological metrics

write_rds(dt_pheno,glue('data/procesada/{sitio}_NDVI_pheno_metrics.rds'))

## Plot results
plot(ts_filled, pheno = dt_pheno, plot_points = TRUE,plot_dates = TRUE)
ggsave(glue('output/phenology_{sitio}_NDVI.png'),
       width =10,heigh = 6,scale=1.2)

