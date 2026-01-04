# List NWPS gauges

Retrieves a list of gauges from the National Water Prediction Service
API, optionally filtered by bounding box and CatFIM configuration.

## Usage

``` r
nwps_gauges(
  bbox = NULL,
  srid = c("EPSG_4326", "EPSG_3857", "SRID_UNSPECIFIED"),
  catfim = NULL
)
```

## Arguments

- bbox:

  Bounding box for spatial filtering. Can be either:

  - A numeric vector of length 4: `c(xmin, ymin, xmax, ymax)`

  - An sf or sfc object (bounding box will be extracted automatically)

  Coordinates should match the spatial reference system specified by
  `srid`. Default is `NULL` (no spatial filter).

- srid:

  Character. Spatial reference system identifier. One of `"EPSG_4326"`
  (WGS84, default), `"EPSG_3857"` (Web Mercator), or
  `"SRID_UNSPECIFIED"`. Ignored when `bbox` is an sf object (CRS is
  extracted automatically).

- catfim:

  Logical. If `TRUE`, filter to only gauges with CatFIM (Categorical
  Flood Inundation Mapping) configuration. Default is `NULL` (no
  filter).

## Value

An sf object with point geometry and one row per gauge containing:

- lid:

  Location identifier (e.g., "ANAW1")

- name:

  Descriptive gauge name

- latitude:

  Latitude in decimal degrees

- longitude:

  Longitude in decimal degrees

- state_abbreviation:

  Two-letter state code

- state_name:

  Full state name

- rfc_abbreviation:

  River Forecast Center abbreviation

- rfc_name:

  River Forecast Center name

- wfo_abbreviation:

  Weather Forecast Office abbreviation

- wfo_name:

  Weather Forecast Office name

- pedts_observed:

  SHEF code for observed data

- pedts_forecast:

  SHEF code for forecast data

- status_observed_primary:

  Latest observed primary value

- status_observed_primary_unit:

  Unit for observed primary value

- status_observed_secondary:

  Latest observed secondary value

- status_observed_secondary_unit:

  Unit for observed secondary value

- status_observed_flood_category:

  Current flood category

- status_observed_valid_time:

  Timestamp of observation (POSIXct)

- status_forecast_primary:

  Latest forecast primary value

- status_forecast_primary_unit:

  Unit for forecast primary value

- status_forecast_secondary:

  Latest forecast secondary value

- status_forecast_secondary_unit:

  Unit for forecast secondary value

- status_forecast_flood_category:

  Forecast flood category

- status_forecast_valid_time:

  Timestamp of forecast (POSIXct)

- geometry:

  Point geometry (sfc_POINT)

## Examples

``` r
if (FALSE) { # \dontrun{
# Get all gauges (may be slow)
all_gauges <- nwps_gauges()

# Get gauges within a bounding box (Washington DC area)
dc_gauges <- nwps_gauges(
  bbox = c(-77.5, 38.5, -76.5, 39.5),
  srid = "EPSG_4326"
)

# Get gauges using an sf object as bbox
library(sf)
area_of_interest <- st_as_sfc(st_bbox(c(xmin = -77.5, ymin = 38.5,
                                         xmax = -76.5, ymax = 39.5),
                                       crs = 4326))
dc_gauges <- nwps_gauges(bbox = area_of_interest)

# Get only gauges with CatFIM configuration
catfim_gauges <- nwps_gauges(catfim = TRUE)
} # }
```
