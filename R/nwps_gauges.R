#' List NWPS gauges
#'
#' Retrieves a list of gauges from the National Water Prediction Service API,
#' optionally filtered by bounding box and CatFIM configuration.
#'
#' @param bbox Bounding box for spatial filtering. Can be either:
#'   - A numeric vector of length 4: `c(xmin, ymin, xmax, ymax)`
#'   - An sf or sfc object (bounding box will be extracted automatically)
#'
#'   Coordinates should match the spatial reference system specified by `srid`.
#'   Default is `NULL` (no spatial filter).
#' @param srid Character. Spatial reference system identifier. One of
#'   `"EPSG_4326"` (WGS84, default), `"EPSG_3857"` (Web Mercator), or
#'   `"SRID_UNSPECIFIED"`. Ignored when `bbox` is an sf object (CRS is
#'   extracted automatically).
#' @param catfim Logical. If `TRUE`, filter to only gauges with CatFIM
#'   (Categorical Flood Inundation Mapping) configuration. Default is `NULL`
#'   (no filter).
#'
#' @return An sf object with point geometry and one row per gauge containing:
#'   \describe{
#'     \item{lid}{Location identifier (e.g., "ANAW1")}
#'     \item{name}{Descriptive gauge name}
#'     \item{latitude}{Latitude in decimal degrees}
#'     \item{longitude}{Longitude in decimal degrees}
#'     \item{state_abbreviation}{Two-letter state code}
#'     \item{state_name}{Full state name}
#'     \item{rfc_abbreviation}{River Forecast Center abbreviation}
#'     \item{rfc_name}{River Forecast Center name}
#'     \item{wfo_abbreviation}{Weather Forecast Office abbreviation}
#'     \item{wfo_name}{Weather Forecast Office name}
#'     \item{pedts_observed}{SHEF code for observed data}
#'     \item{pedts_forecast}{SHEF code for forecast data}
#'     \item{status_observed_primary}{Latest observed primary value}
#'     \item{status_observed_primary_unit}{Unit for observed primary value}
#'     \item{status_observed_secondary}{Latest observed secondary value}
#'     \item{status_observed_secondary_unit}{Unit for observed secondary value}
#'     \item{status_observed_flood_category}{Current flood category}
#'     \item{status_observed_valid_time}{Timestamp of observation (POSIXct)}
#'     \item{status_forecast_primary}{Latest forecast primary value}
#'     \item{status_forecast_primary_unit}{Unit for forecast primary value}
#'     \item{status_forecast_secondary}{Latest forecast secondary value}
#'     \item{status_forecast_secondary_unit}{Unit for forecast secondary value}
#'     \item{status_forecast_flood_category}{Forecast flood category}
#'     \item{status_forecast_valid_time}{Timestamp of forecast (POSIXct)}
#'     \item{geometry}{Point geometry (sfc_POINT)}
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get all gauges (may be slow)
#' all_gauges <- nwps_gauges()
#'
#' # Get gauges within a bounding box (Washington DC area)
#' dc_gauges <- nwps_gauges(
#'   bbox = c(-77.5, 38.5, -76.5, 39.5),
#'   srid = "EPSG_4326"
#' )
#'
#' # Get gauges using an sf object as bbox
#' library(sf)
#' area_of_interest <- st_as_sfc(st_bbox(c(xmin = -77.5, ymin = 38.5,
#'                                          xmax = -76.5, ymax = 39.5),
#'                                        crs = 4326))
#' dc_gauges <- nwps_gauges(bbox = area_of_interest)
#'
#' # Get only gauges with CatFIM configuration
#' catfim_gauges <- nwps_gauges(catfim = TRUE)
#' }
nwps_gauges <- function(bbox = NULL,
                        srid = c("EPSG_4326", "EPSG_3857", "SRID_UNSPECIFIED"),
                        catfim = NULL) {
  srid <- match.arg(srid)

  bbox_vec <- extract_bbox(bbox)

  if (!is.null(bbox_vec)) {
    if (bbox_vec[1] >= bbox_vec[3]) {
      cli::cli_abort("{.arg bbox} xmin must be less than xmax.")
    }
    if (bbox_vec[2] >= bbox_vec[4]) {
      cli::cli_abort("{.arg bbox} ymin must be less than ymax.")
    }
  }

  if (!is.null(catfim) && !is.logical(catfim)) {
    cli::cli_abort("{.arg catfim} must be {.code TRUE}, {.code FALSE}, or {.code NULL}.")
  }

  query <- list(
    `bbox.xmin` = if (!is.null(bbox_vec)) bbox_vec[1] else NULL,
    `bbox.ymin` = if (!is.null(bbox_vec)) bbox_vec[2] else NULL,
    `bbox.xmax` = if (!is.null(bbox_vec)) bbox_vec[3] else NULL,
    `bbox.ymax` = if (!is.null(bbox_vec)) bbox_vec[4] else NULL,
    srid = if (!is.null(bbox_vec)) srid else NULL,
    catfim = if (!is.null(catfim)) tolower(as.character(catfim)) else NULL
  )

  response <- nwps_request("/gauges", query = query)

  gauges_list <- response[["gauges"]]

  if (length(gauges_list) == 0) {
    cli::cli_inform("No gauges found matching the specified criteria.")
    empty_df <- tibble::tibble(
      lid = character(),
      name = character(),
      latitude = double(),
      longitude = double(),
      state_abbreviation = character(),
      state_name = character(),
      rfc_abbreviation = character(),
      rfc_name = character(),
      wfo_abbreviation = character(),
      wfo_name = character(),
      pedts_observed = character(),
      pedts_forecast = character(),
      status_observed_primary = double(),
      status_observed_primary_unit = character(),
      status_observed_secondary = double(),
      status_observed_secondary_unit = character(),
      status_observed_flood_category = character(),
      status_observed_valid_time = as.POSIXct(character()),
      status_forecast_primary = double(),
      status_forecast_primary_unit = character(),
      status_forecast_secondary = double(),
      status_forecast_secondary_unit = character(),
      status_forecast_flood_category = character(),
      status_forecast_valid_time = as.POSIXct(character())
    )
    return(as_sf_points(empty_df))
  }

  gauges_parsed <- lapply(gauges_list, parse_gauge)

  gauges_df <- dplyr::bind_rows(gauges_parsed)

  as_sf_points(gauges_df)
}

#' Parse a single gauge response object into a one-row tibble
#'
#' @param gauge List. A single gauge object from the API response.
#'
#' @return A one-row tibble with flattened gauge data.
#'
#' @noRd
parse_gauge <- function(gauge) {
  tibble::tibble(
    lid = gauge[["lid"]] %||% NA_character_,
    name = gauge[["name"]] %||% NA_character_,
    latitude = gauge[["latitude"]] %||% NA_real_,
    longitude = gauge[["longitude"]] %||% NA_real_,
    state_abbreviation = gauge[["state"]][["abbreviation"]] %||% NA_character_,
    state_name = gauge[["state"]][["name"]] %||% NA_character_,
    rfc_abbreviation = gauge[["rfc"]][["abbreviation"]] %||% NA_character_,
    rfc_name = gauge[["rfc"]][["name"]] %||% NA_character_,
    wfo_abbreviation = gauge[["wfo"]][["abbreviation"]] %||% NA_character_,
    wfo_name = gauge[["wfo"]][["name"]] %||% NA_character_,
    pedts_observed = gauge[["pedts"]][["observed"]] %||% NA_character_,
    pedts_forecast = gauge[["pedts"]][["forecast"]] %||% NA_character_,
    status_observed_primary = gauge[["status"]][["observed"]][["primary"]] %||% NA_real_,
    status_observed_primary_unit = gauge[["status"]][["observed"]][["primaryUnit"]] %||% NA_character_,
    status_observed_secondary = gauge[["status"]][["observed"]][["secondary"]] %||% NA_real_,
    status_observed_secondary_unit = gauge[["status"]][["observed"]][["secondaryUnit"]] %||% NA_character_,
    status_observed_flood_category = gauge[["status"]][["observed"]][["floodCategory"]] %||% NA_character_,
    status_observed_valid_time = parse_timestamp(gauge[["status"]][["observed"]][["validTime"]]),
    status_forecast_primary = gauge[["status"]][["forecast"]][["primary"]] %||% NA_real_,
    status_forecast_primary_unit = gauge[["status"]][["forecast"]][["primaryUnit"]] %||% NA_character_,
    status_forecast_secondary = gauge[["status"]][["forecast"]][["secondary"]] %||% NA_real_,
    status_forecast_secondary_unit = gauge[["status"]][["forecast"]][["secondaryUnit"]] %||% NA_character_,
    status_forecast_flood_category = gauge[["status"]][["forecast"]][["floodCategory"]] %||% NA_character_,
    status_forecast_valid_time = parse_timestamp(gauge[["status"]][["forecast"]][["validTime"]])
  )
}

#' Parse ISO 8601 timestamp to POSIXct
#'
#' @param timestamp Character. An ISO 8601 formatted timestamp or NULL.
#'
#' @return POSIXct datetime in UTC, or NA if input is NULL or invalid.
#'
#' @noRd
parse_timestamp <- function(timestamp) {
  if (is.null(timestamp) || is.na(timestamp) || timestamp == "") {
    return(as.POSIXct(NA_character_))
  }
  as.POSIXct(timestamp, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
}
