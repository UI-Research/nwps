# Get stage/flow product by PEDTS code

Retrieves stage/flow time series data for a specific SHEF Physical
Element Data Type Source (PEDTS) code. This provides more granular
control over which specific data product to retrieve compared to
[`nwps_gauge_stageflow()`](https://ui-research.github.io/nwps/reference/nwps_gauge_stageflow.md).

## Usage

``` r
nwps_product_stageflow(identifier, pedts)
```

## Arguments

- identifier:

  Character. Gauge LID (e.g., "PTTP1") or USGS ID.

- pedts:

  Character. SHEF PEDTS code specifying the data product (e.g., "HGIRG"
  for observed stage, "HGIFF" for forecast stage).

## Value

A tibble with columns:

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
# Get observed stage data
observed <- nwps_product_stageflow("PTTP1", "HGIRG")

# Get forecast stage data
forecast <- nwps_product_stageflow("PTTP1", "HGIFF")
} # }
```
