# Get NWPS system monitoring status

Retrieves system health and data status information from the NWPS API,
including gauge flood statistics, HML (Hydrologic Message Language)
processing stats, and LRO (Long Range Outlook) data status.

## Usage

``` r
nwps_monitor()
```

## Value

A list containing:

- gauge_observed:

  A tibble with counts of gauges by observed flood category

- gauge_forecast:

  A tibble with counts of gauges by forecast flood category

- hml_job_queue:

  Integer count of jobs in the HML processing queue

- hml_product_counts:

  A tibble with HML product counts by time period

- hml_last_received:

  A tibble with timestamps of last HML receipt by WFO

- lro:

  A tibble with current LRO count and interval

## Examples

``` r
if (FALSE) { # \dontrun{
status <- nwps_monitor()
status$gauge_observed
status$hml_product_counts
} # }
```
