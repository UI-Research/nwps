# Get gauge stage-to-flow ratings

Retrieves the stage-to-flow rating curve data for a gauge. Rating curves
define the relationship between water level (stage) and discharge
(flow).

## Usage

``` r
nwps_gauge_ratings(
  identifier,
  limit = 10000,
  sort = c("ASC", "DESC"),
  only_tenths = FALSE
)
```

## Arguments

- identifier:

  Character. Gauge LID (e.g., "PTTP1") or USGS ID.

- limit:

  Integer. Maximum number of rating points to return. Default is 10000.

- sort:

  Character. Sort order by stage value. One of `"ASC"` (ascending,
  default) or `"DESC"` (descending).

- only_tenths:

  Logical. If `TRUE`, filter results to only include stage values at
  tenths-of-foot increments. Default is `FALSE`.

## Value

A tibble with columns:

- stage:

  Water level value

- stage_units:

  Units for stage (typically "ft")

- flow:

  Discharge value corresponding to the stage

- flow_units:

  Units for flow (typically "cfs")

## Examples

``` r
if (FALSE) { # \dontrun{
# Get rating curve for a gauge
ratings <- nwps_gauge_ratings("PTTP1")

# Get only tenths-of-foot increments, sorted descending
ratings <- nwps_gauge_ratings("PTTP1", only_tenths = TRUE, sort = "DESC")
} # }
```
