# Get gauge stage/flow data

Retrieves observed and/or forecast stage and flow time series data for a
gauge.

## Usage

``` r
nwps_gauge_stageflow(identifier, product = NULL)
```

## Arguments

- identifier:

  Character. Gauge LID (e.g., "PTTP1") or USGS ID.

- product:

  Character. Which product to retrieve: `"observed"`, `"forecast"`, or
  `NULL` (default) for both.

## Value

A tibble with columns:

- product:

  Product type ("observed" or "forecast")

- pedts:

  SHEF Physical Element Data Type code

- issued_time:

  When the data was issued (POSIXct)

- wfo:

  Weather Forecast Office abbreviation

- time_zone:

  Time zone for the data

- valid_time:

  Observation/forecast valid time (POSIXct)

- generated_time:

  When the data point was generated (POSIXct)

- primary:

  Primary value (typically stage)

- primary_name:

  Name of primary measurement

- primary_units:

  Units for primary value

- secondary:

  Secondary value (typically flow)

- secondary_name:

  Name of secondary measurement

- secondary_units:

  Units for secondary value

## Examples

``` r
if (FALSE) { # \dontrun{
# Get both observed and forecast data
all_data <- nwps_gauge_stageflow("PTTP1")

# Get only observed data
observed <- nwps_gauge_stageflow("PTTP1", product = "observed")

# Get only forecast data
forecast <- nwps_gauge_stageflow("PTTP1", product = "forecast")
} # }
```
