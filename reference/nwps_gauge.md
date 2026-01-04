# Get gauge metadata

Retrieves detailed metadata for a single NWPS gauge by its identifier.

## Usage

``` r
nwps_gauge(identifier)
```

## Arguments

- identifier:

  Character. Gauge LID (e.g., "ANAD2") or USGS ID (e.g., "01651750").

## Value

A list containing gauge metadata with the following components:

- metadata:

  An sf object (point geometry) with basic gauge information (lid,
  usgsId, reachId, name, description, latitude, longitude, timeZone,
  county)

- organizations:

  A tibble with RFC, WFO, and state information

- pedts:

  A tibble with SHEF codes for observed and forecast data

- status:

  A tibble with current observed and forecast status

- flood_categories:

  A tibble with flood stage/flow thresholds

- flood_crests:

  A tibble with historic and recent flood crests

- flood_impacts:

  A tibble with stage-based impact statements

- low_waters:

  A tibble with historic low water records

- datums:

  A tibble with vertical and horizontal datum information if present,
  NULL otherwise

- images:

  A list with URLs for hydrograph and other images

## Examples

``` r
if (FALSE) { # \dontrun{
gauge <- nwps_gauge("ANAD2")
gauge$metadata
gauge$flood_categories
} # }
```
