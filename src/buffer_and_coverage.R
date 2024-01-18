library(sf) # to work with geospatial vector data
library(mapview)  # to visualize geospatial data in a fast way
library(dplyr) # to do data wrangling
library(qgisprocess) #to use qgisprocess in R
library(terra)  # to work with rasters
library(tictoc) # to check how long computation takes

# Grid Vlaams Brabant
vlaams_brabant <- sf::st_read(
  here::here("data", "raw", "Grid_VlaamsBrabant.shp")
)

# Preview (sample used)
vlaams_brabant_sample <- vlaams_brabant %>%
  dplyr::slice_sample(n = 10000)
mapview::mapview(vlaams_brabant_sample)

# NARA land use
land_use <- terra::rast("./data/raw/Landgebruikskaart NARA-T 2014_niv21.tif")

# Create buffers of 250m (default is 5 line segments used to approximate a
# quarter circle when creating rounded offsets)
#For higher precision: increase SEGMENTS arg value
tic()
vlaams_brabant_circles <- qgis_run_algorithm(
  "native:buffer",
  INPUT = vlaams_brabant,
  SEGMENTS = 5, # default value: 5
  DISTANCE = 250, # distance in meter
  DISSOLVE = FALSE
)
vlaams_brabant_circles <- sf::st_as_sf(vlaams_brabant_circles)
toc()

# Creating buffers via sf (here below) takes longer
# tic()
# vlaams_brabant_circles <- sf::st_buffer(x = vlaams_brabant, 
#                                         dist = 250, 
#                                         nQuadSegs = 5
# )
# toc()

# Preview of the buffers (sample used)
vlaams_brabant_circles_sample <- vlaams_brabant_circles %>%
  dplyr::slice_sample(n = 1000)
mapview::mapview(vlaams_brabant_circles_sample)

# Save the buffers as interim result
sf::st_write(obj = vlaams_brabant_circles,
             dsn = "./data/interim/vlaams_brabant_buffer_250m.gpkg")

tic()
vlaams_brabant_circles_land_use_frac <- exactextractr::exact_extract(
  x = land_use,
  y = vlaams_brabant_circles,
  fun = c("frac")
)
toc()

# Add the fraction values as columns to the buffer spatial data.frame
vlaams_brabant_circles_land_use_frac <- 
  dplyr::bind_cols(
    vlaams_brabant_circles, 
    vlaams_brabant_circles_land_use_frac
)

# Save the buffers with the fractions of land use category as interim result
sf::st_write(
  obj = vlaams_brabant_circles_land_use_frac,
  dsn = "./data/interim/vlaams_brabant_circles_land_use_frac_250m.gpkg"
)

# Preview
vlaams_brabant_circles_land_use_frac_sample <- 
  vlaams_brabant_circles_land_use_frac %>%
  dplyr::slice_sample(n = 1000)
mapview::mapview(vlaams_brabant_circles_land_use_frac_sample)
