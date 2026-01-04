# CLAUDE.md - nwps Package Development Guidelines

## Package Overview

**Package Name:** nwps
**Purpose:** Provide R functions to access all endpoints of the National Water Prediction Service (NWPS) API (https://api.water.noaa.gov/nwps/v1/)

The NWPS API provides hydrological data including:
- Gauge metadata, ratings, and stage/flow observations/forecasts
- NWM (National Water Model) reach metadata and streamflow forecasts
- Stage/flow products by SHEF (Standard Hydrologic Exchange Format) codes

---

## API Endpoints and Corresponding Functions

| Endpoint | Function Name | Description |
|----------|---------------|-------------|
| `GET /gauges` | `nwps_gauges()` | List gauges with optional bounding box and filters |
| `GET /gauges/{identifier}` | `nwps_gauge()` | Get single gauge metadata by LID or USGS ID |
| `GET /gauges/{identifier}/ratings` | `nwps_gauge_ratings()` | Get stage-to-flow rating curve data |
| `GET /gauges/{identifier}/stageflow` | `nwps_gauge_stageflow()` | Get all observed and forecast stage/flow data |
| `GET /gauges/{identifier}/stageflow/{product}` | `nwps_gauge_stageflow()` | Get observed OR forecast data (via `product` parameter) |
| `GET /reaches/{reachId}` | `nwps_reach()` | Get NWM reach metadata |
| `GET /reaches/{reachId}/streamflow` | `nwps_reach_streamflow()` | Get NWM streamflow forecasts for a reach |
| `GET /products/stageflow/{identifier}/{pedts}` | `nwps_product_stageflow()` | Get stage/flow by SHEF PEDTS code |
| `GET /monitor` | `nwps_monitor()` | Get system health and data status |

---

## File Structure

```
nwps/
├── DESCRIPTION
├── NAMESPACE
├── LICENSE
├── README.md
├── CLAUDE.md
├── R/
│   ├── nwps_gauges.R
│   ├── nwps_gauge.R
│   ├── nwps_gauge_ratings.R
│   ├── nwps_gauge_stageflow.R
│   ├── nwps_reach.R
│   ├── nwps_reach_streamflow.R
│   ├── nwps_product_stageflow.R
│   ├── nwps_monitor.R
│   ├── utils.R
│   └── nwps-package.R
├── man/
├── tests/
│   ├── testthat.R
│   └── testthat/
│       ├── test-nwps_gauges.R
│       ├── test-nwps_gauge.R
│       ├── test-nwps_gauge_ratings.R
│       ├── test-nwps_gauge_stageflow.R
│       ├── test-nwps_reach.R
│       ├── test-nwps_reach_streamflow.R
│       ├── test-nwps_product_stageflow.R
│       └── test-nwps_monitor.R
└── vignettes/
    └── nwps-intro.Rmd
```

---

## Code Conventions

### General R Style
- Follow tidyverse style guidelines (https://style.tidyverse.org/)
- Use snake_case for all function and variable names
- Use `|>` (base R pipe) everywhere
- Prefix all exported functions with `nwps_`
- Do not place closing parentheses or brackets on new lines

### Variable Naming
- Do not overwrite existing objects; create numbered versions if transformation is needed
- Use descriptive names: `gauge_metadata` not `gm`, `response_content` not `rc`

### Function Design
- Each .R file contains one primary exported function
- Helper functions used only within that file stay in the same file
- Helper functions used across multiple files go in `utils.R`
- All exported functions must have roxygen2 documentation

### Dependencies
The package should minimize dependencies. Required packages:
- **httr2**: For HTTP requests (modern replacement for httr)
- **jsonlite**: For JSON parsing
- **tibble**: For returning tidy data frames
- **cli**: For user-friendly messages and errors
- **rlang**: For tidy evaluation and error handling
- **dplyr**: For data manipulation that is easy to understand
- **tidyr**: For data restructuring
- **stringr**: For a consistent interface for working with strings

### Suggested packages (in Suggests, not Imports):
- **sf**: For converting spatial data to sf objects
- **testthat**: For testing

---

## API Request Handling

### Base URL
```r
NWPS_BASE_URL <- "https://api.water.noaa.gov/nwps/v1"
```

### Request Pattern
All API functions should use a consistent internal helper in `utils.R`:

```r
nwps_request <- function(endpoint, query = list()) {

# Build request, handle errors, parse JSON, return tibble
}
```

### Error Handling
- Use httr2's built-in retry and error handling
- Provide informative error messages using cli
- Handle common errors:
  - 404: Invalid gauge/reach identifier
  - 400: Invalid parameters
  - 500: Server errors (suggest retry)

### Response Processing
- Always return tibbles, not data frames or lists
- Flatten nested JSON structures where sensible
- Convert timestamps to POSIXct
- Keep original column names from API (snake_case conversion optional)

---

## Function Documentation Standards

Every exported function must include:

```r
#' @title Short title
#' @description Longer description of what the function does
#' @param param_name Description of parameter
#' @return Description of return value (always a tibble)
#' @export
#' @examples
#' \dontrun{
#' # Example usage
#' }
```

---

## Parameter Conventions

### Identifier Parameters
- `identifier`: Accepts either LID (e.g., "ANAW1") or USGS ID (e.g., "13334300")
- `reach_id`: NWM reach identifier (integer stored as character)

### Bounding Box Parameters
For `nwps_gauges()`, use a single `bbox` parameter:
```r
nwps_gauges(bbox = c(xmin, ymin, xmax, ymax), srid = "EPSG_4326")
```

### Enum Parameters
Use match.arg() for parameters with fixed options:
- `srid`: "EPSG_4326" (default), "EPSG_3857"
- `product`: "observed", "forecast", or NULL for both
- `series`: "analysis_assimilation", "short_range", "medium_range", "long_range", "medium_range_blend"
- `sort`: "ASC", "DESC"

---

## Testing Guidelines

### Test File Structure
- One test file per exported function
- Use httptest2 or webmockr for mocking API responses
- Include tests for:
  - Successful requests with valid parameters
  - Parameter validation
  - Error handling for invalid identifiers
  - Edge cases (empty responses, missing fields)

### Test Naming
```r
test_that("nwps_gauge returns tibble for valid LID", { ... })
test_that("nwps_gauge errors for invalid identifier", { ... })
```

---

## User Messages

- Use `cli::cli_inform()` for informational messages
- Use `cli::cli_warn()` for warnings
- Use `cli::cli_abort()` for errors
- Only print messages for:
  - Significant methodological assumptions
  - Partial data returns
  - API deprecation notices
- Do NOT print routine progress messages

---

## Example Function Template

```r
#' Get gauge metadata
#'
#' Retrieves metadata for a single NWPS gauge by its identifier.
#'
#' @param identifier Character. Gauge LID (e.g., "ANAW1") or USGS ID (e.g., "13334300").
#'
#' @return A tibble with gauge metadata including location, flood categories,
#'   and associated identifiers.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' nwps_gauge("ANAW1")
#' nwps_gauge("13334300")
#' }
nwps_gauge <- function(identifier) {

 identifier <- as.character(identifier)

 response <- nwps_request(
   endpoint = paste0("/gauges/", identifier)
 )

 response
}
```

---

## Version Control

- Use conventional commits (feat:, fix:, docs:, test:, refactor:)
- Create feature branches for new endpoints
- All code must pass R CMD check with no warnings or notes before merging

---

## CRAN Submission Checklist

Before submitting to CRAN:
- [ ] All examples run or are wrapped in `\dontrun{}`
- [ ] Vignette builds without API calls (use pre-computed results)
- [ ] No hardcoded file paths
- [ ] LICENSE file matches DESCRIPTION
- [ ] All URLs in documentation are valid
- [ ] Package passes R CMD check on multiple platforms
