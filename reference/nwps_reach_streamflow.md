# Get NWM reach streamflow forecasts

Retrieves National Water Model streamflow forecasts for a reach.
Different forecast series are available with varying time horizons and
ensemble configurations.

## Usage

``` r
nwps_reach_streamflow(
  reach_id,
  series = c("short_range", "analysis_assimilation", "medium_range",
    "medium_range_blend", "long_range")
)
```

## Arguments

- reach_id:

  Character or numeric. The NWM reach identifier.

- series:

  Character. The forecast series to retrieve. One of:

  "analysis_assimilation"

  :   Analysis and assimilation (recent past)

  "short_range"

  :   Short-range forecast (0-18 hours)

  "medium_range"

  :   Medium-range ensemble forecast (0-10 days)

  "medium_range_blend"

  :   Blended medium-range forecast

  "long_range"

  :   Long-range ensemble forecast (0-30 days)

  Default is `"short_range"`.

## Value

A tibble with columns:

- reach_id:

  NWM reach identifier

- series:

  Forecast series name

- member:

  Ensemble member name (e.g., "series", "mean", "member1")

- reference_time:

  Forecast reference/initialization time (POSIXct)

- valid_time:

  Forecast valid time (POSIXct)

- flow:

  Streamflow value

- units:

  Flow units (typically "ft³/s")

## Examples

``` r
if (FALSE) { # \dontrun{
# Get short-range forecast
short <- nwps_reach_streamflow("22338099", series = "short_range")

# Get medium-range ensemble forecast
medium <- nwps_reach_streamflow("22338099", series = "medium_range")
} # }
```
