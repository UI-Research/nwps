# Get NWM reach metadata

Retrieves metadata for a National Water Model (NWM) reach, including
location, available streamflow products, and upstream/downstream
routing.

## Usage

``` r
nwps_reach(reach_id)
```

## Arguments

- reach_id:

  Character or numeric. The NWM reach identifier.

## Value

A list containing:

- metadata:

  An sf object (point geometry) with reach_id, name, latitude, longitude

- streamflow_products:

  Character vector of available streamflow forecast types (e.g.,
  "short_range", "medium_range")

- upstream:

  A tibble of upstream reaches with reach_id and stream_order

- downstream:

  A tibble of downstream reaches with reach_id and stream_order

## Examples

``` r
if (FALSE) { # \dontrun{
reach <- nwps_reach("22338099")
reach$metadata
reach$upstream
} # }
```
