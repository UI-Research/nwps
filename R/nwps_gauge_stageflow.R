#' Get gauge stage/flow data
#'
#' Retrieves observed and/or forecast stage and flow time series data for
#' a gauge.
#'
#' @param identifier Character. Gauge LID (e.g., "PTTP1") or USGS ID.
#' @param product Character. Which product to retrieve: `"observed"`,
#'   `"forecast"`, or `NULL` (default) for both.
#'
#' @return A tibble with columns:
#'   \describe{
#'     \item{product}{Product type ("observed" or "forecast")}
#'     \item{pedts}{SHEF Physical Element Data Type code}
#'     \item{issued_time}{When the data was issued (POSIXct)}
#'     \item{wfo}{Weather Forecast Office abbreviation}
#'     \item{time_zone}{Time zone for the data}
#'     \item{valid_time}{Observation/forecast valid time (POSIXct)}
#'     \item{generated_time}{When the data point was generated (POSIXct)}
#'     \item{primary}{Primary value (typically stage)}
#'     \item{primary_name}{Name of primary measurement}
#'     \item{primary_units}{Units for primary value}
#'     \item{secondary}{Secondary value (typically flow)}
#'     \item{secondary_name}{Name of secondary measurement}
#'     \item{secondary_units}{Units for secondary value}
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get both observed and forecast data
#' all_data <- nwps_gauge_stageflow("PTTP1")
#'
#' # Get only observed data
#' observed <- nwps_gauge_stageflow("PTTP1", product = "observed")
#'
#' # Get only forecast data
#' forecast <- nwps_gauge_stageflow("PTTP1", product = "forecast")
#' }
nwps_gauge_stageflow <- function(identifier, product = NULL) {
  identifier <- as.character(identifier)

  if (identifier == "" || is.na(identifier)) {
    cli::cli_abort("{.arg identifier} must be a non-empty string.")
  }

  if (!is.null(product)) {
    product <- match.arg(product, choices = c("observed", "forecast"))
    endpoint <- paste0("/gauges/", identifier, "/stageflow/", product)
  } else {
    endpoint <- paste0("/gauges/", identifier, "/stageflow")
  }

  response <- nwps_request(endpoint)

  if (!is.null(product)) {
    result <- parse_stageflow_product(response, product)
  } else {
    observed <- parse_stageflow_product(response[["observed"]], "observed")
    forecast <- parse_stageflow_product(response[["forecast"]], "forecast")
    result <- dplyr::bind_rows(observed, forecast)
  }

  result
}

#' Parse a single stageflow product response
#'
#' @param product_data List. The product data from API response.
#' @param product_type Character. "observed" or "forecast".
#'
#' @return A tibble with parsed stageflow data.
#'
#' @noRd
parse_stageflow_product <- function(product_data, product_type) {
  if (is.null(product_data)) {
    return(tibble::tibble(
      product = character(),
      pedts = character(),
      issued_time = as.POSIXct(character()),
      wfo = character(),
      time_zone = character(),
      valid_time = as.POSIXct(character()),
      generated_time = as.POSIXct(character()),
      primary = double(),
      primary_name = character(),
      primary_units = character(),
      secondary = double(),
      secondary_name = character(),
      secondary_units = character()
    ))
  }

  pedts <- product_data[["pedts"]] %||% NA_character_
  issued_time <- parse_timestamp(product_data[["issuedTime"]])
  wfo <- product_data[["wfo"]] %||% NA_character_
  time_zone <- product_data[["timeZone"]] %||% NA_character_
  primary_name <- product_data[["primaryName"]] %||% NA_character_
  primary_units <- product_data[["primaryUnits"]] %||% NA_character_
  secondary_name <- product_data[["secondaryName"]] %||% NA_character_
  secondary_units <- product_data[["secondaryUnits"]] %||% NA_character_

  data <- product_data[["data"]]

  if (is.null(data) || length(data) == 0) {
    return(tibble::tibble(
      product = product_type,
      pedts = pedts,
      issued_time = issued_time,
      wfo = wfo,
      time_zone = time_zone,
      valid_time = as.POSIXct(NA),
      generated_time = as.POSIXct(NA),
      primary = NA_real_,
      primary_name = primary_name,
      primary_units = primary_units,
      secondary = NA_real_,
      secondary_name = secondary_name,
      secondary_units = secondary_units
    )[0, ])
  }

  rows <- lapply(data, function(d) {
    tibble::tibble(
      product = product_type,
      pedts = pedts,
      issued_time = issued_time,
      wfo = wfo,
      time_zone = time_zone,
      valid_time = parse_timestamp(d[["validTime"]]),
      generated_time = parse_timestamp(d[["generatedTime"]]),
      primary = d[["primary"]] %||% NA_real_,
      primary_name = primary_name,
      primary_units = primary_units,
      secondary = d[["secondary"]] %||% NA_real_,
      secondary_name = secondary_name,
      secondary_units = secondary_units
    )
  })

  dplyr::bind_rows(rows)
}
