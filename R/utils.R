#' Base URL for the NWPS API
#' @noRd
NWPS_BASE_URL <- "https://api.water.noaa.gov/nwps/v1"

#' Make a request to the NWPS API
#'
#' Internal helper function that handles all HTTP requests to the NWPS API.
#'
#' @param endpoint Character. The API endpoint path (e.g., "/gauges").
#' @param query Named list. Query parameters to include in the request.
#'
#' @return Parsed JSON response as a list.
#'
#' @noRd
nwps_request <- function(endpoint, query = list()) {
  url <- paste0(NWPS_BASE_URL, endpoint)

  query_filtered <- Filter(Negate(is.null), query)

  request <- httr2::request(url) |>
    httr2::req_url_query(!!!query_filtered) |>
    httr2::req_user_agent("nwps R package (https://github.com/user/nwps)") |>
    httr2::req_retry(max_tries = 3, backoff = ~ 2)

  response <- tryCatch(
    httr2::req_perform(request),
    httr2_http_404 = function(cnd) {
      cli::cli_abort(
        c(

"Resource not found.",
          "i" = "Check that the identifier or endpoint is correct.",
          "x" = "API returned 404 for: {.url {url}}"
        ),
        call = rlang::caller_env(n = 4)
      )
    },
    httr2_http_400 = function(cnd) {
      cli::cli_abort(
        c(
          "Invalid request parameters.",
          "i" = "Check that all parameters are valid.",
          "x" = "API returned 400 for: {.url {url}}"
        ),
        call = rlang::caller_env(n = 4)
      )
    },
    httr2_http_500 = function(cnd) {
      cli::cli_abort(
        c(
          "NWPS API server error.",
          "i" = "The server may be temporarily unavailable. Try again later.",
          "x" = "API returned 500 for: {.url {url}}"
        ),
        call = rlang::caller_env(n = 4)
      )
    },
    error = function(cnd) {
      cli::cli_abort(
        c(
          "Failed to connect to NWPS API.",
          "i" = "Check your internet connection.",
          "x" = "Error: {conditionMessage(cnd)}"
        ),
        call = rlang::caller_env(n = 4)
      )
    }
  )

  content <- httr2::resp_body_json(response)

  content
}

#' Extract bounding box from various input types
#'
#' Accepts either a numeric vector of length 4 (xmin, ymin, xmax, ymax) or
#' an sf/sfc object and returns a numeric bbox vector.
#'
#' @param bbox Numeric vector of length 4 or an sf/sfc object.
#'
#' @return Numeric vector c(xmin, ymin, xmax, ymax).
#'
#' @noRd
extract_bbox <- function(bbox) {
  if (is.null(bbox)) {
    return(NULL)
  }

 if (inherits(bbox, c("sf", "sfc", "bbox"))) {
    bbox_extracted <- sf::st_bbox(bbox)
    return(as.numeric(bbox_extracted[c("xmin", "ymin", "xmax", "ymax")]))
  }

  if (is.numeric(bbox) && length(bbox) == 4) {
    return(bbox)
  }

  cli::cli_abort(
    c(
      "{.arg bbox} must be a numeric vector of length 4 or an sf/sfc object.",
      "i" = "Expected format: {.code c(xmin, ymin, xmax, ymax)} or an sf object."
    )
  )
}

#' Convert a tibble with latitude/longitude to an sf object
#'
#' @param data A tibble containing latitude and longitude columns.
#' @param lon_col Character. Name of the longitude column.
#' @param lat_col Character. Name of the latitude column.
#' @param crs Integer. Coordinate reference system EPSG code. Default is 4326.
#'
#' @return An sf object with point geometry.
#'
#' @noRd
as_sf_points <- function(data, lon_col = "longitude", lat_col = "latitude", crs = 4326) {
  if (nrow(data) == 0) {
    empty_sf <- sf::st_sf(
      data,
      geometry = sf::st_sfc(crs = crs)
    )
    return(empty_sf)
  }

  has_valid_coords <- !is.na(data[[lon_col]]) & !is.na(data[[lat_col]])

  if (!any(has_valid_coords)) {
    empty_sf <- sf::st_sf(
      data,
      geometry = sf::st_sfc(lapply(seq_len(nrow(data)), function(x) sf::st_point()), crs = crs)
    )
    return(empty_sf)
  }

  sf_data <- sf::st_as_sf(
    data,
    coords = c(lon_col, lat_col),
    crs = crs,
    remove = FALSE
  )

  sf_data
}
