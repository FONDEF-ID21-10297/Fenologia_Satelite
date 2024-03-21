library(rstac)
library(gdalcubes)
library(sf)
library(earthdatalogin)
library(glue)
edl_netrc(username = 'frzambra@gmail.com',password = 'Traplozx398#')
with_gdalcubes()

sitio <- 'rio_claro'
layers <- st_layers(glue('data/procesada/{sitio}.gpkg'))
pol <- read_sf(glue('data/procesada/{sitio}.gpkg'),layer = 'borde_cuartel')

bb <- st_bbox(pol) |> 
  as.numeric()

inicio <- "2022-07-01"
fin <- "2022-07-31"

url <- "https://earth-search.aws.element84.com/v0" #Sentinel 2
#url <- "https://cmr.earthdata.nasa.gov/stac/LPCLOUD" #HLSS

items <- stac(url) |> 
  stac_search(collections = "sentinel-s2-l2a-cogs",
              bbox = bb,
              datetime = paste(inicio,fin, sep = "/")) |>
  post_request() |>
  items_fetch()   
  #items_filter(filter_fn = \(x) {x$properties[["eo:cloud_cover"]] < 20})


bb <- pol |> 
  st_transform(32719) |> 
  st_bbox() |> 
  as.numeric()

v = cube_view(srs = "EPSG:32719",
              extent = list(t0 = as.character(inicio), 
                            t1 = as.character(fin),
                            left = bb[1], right = bb[3],
                            top = bb[4], bottom = bb[2]),
              dx = 10, dy = 10, dt = "P5D")

col <- stac_image_collection(items$features, 
                             asset_names = c("B02", "B03", "B04","B08", "SCL"))

cloud_mask <- image_mask("SCL", values=c(3,8,9))

dir_out <- '/mnt/data_procesada/data/rasters/Proyectos/FONDEF_ID21I10297/'

raster_cube(col, v, mask=cloud_mask) |>
  select_bands(c("B02","B03", "B04","B08")) |> 
  write_tif(glue('{dir_out}/HLS_{sitio}'))

