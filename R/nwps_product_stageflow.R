#' Get stage/flow product by PEDTS code
#'
#' Retrieves stage/flow time series data for a specific SHEF Physical Element
#' Data Type Source (PEDTS) code. This provides more granular control over
#' which specific data product to retrieve compared to `nwps_gauge_stageflow()`.
#'
#' @param identifier Character. Gauge LID (e.g., "PTTP1") or USGS ID.
#' @param pedts Character. SHEF PEDTS code specifying the data product
#'   (e.g., "HGIRG" for observed stage, "HGIFF" for forecast stage).
#'
#' @return A tibble with columns:
#'   \describe{
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
#' # Get observed stage data
#' observed <- nwps_product_stageflow("PTTP1", "HGIRG")
#'
#' # Get forecast stage data
#' forecast <- nwps_product_stageflow("PTTP1", "HGIFF")
#' }
nwps_product_stageflow <- function(identifier, pedts) {
  identifier <- as.character(identifier)
  pedts <- as.character(pedts)

  if (identifier == "" || is.na(identifier)) {
    cli::cli_abort("{.arg identifier} must be a non-empty string.")
  }

  if (pedts == "" || is.na(pedts)) {
    cli::cli_abort("{.arg pedts} must be a non-empty string.")
  }

  endpoint <- paste0("/products/stageflow/", identifier, "/", pedts)
  response <- nwps_request(endpoint)

  pedts_resp <- response[["pedts"]] %||% pedts
  issued_time <- parse_timestamp(response[["issuedTime"]])
  wfo <- response[["wfo"]] %||% NA_character_
  time_zone <- response[["timeZone"]] %||% NA_character_
  primary_name <- response[["primaryName"]] %||% NA_character_
  primary_units <- response[["primaryUnits"]] %||% NA_character_
  secondary_name <- response[["secondaryName"]] %||% NA_character_
  secondary_units <- response[["secondaryUnits"]] %||% NA_character_

  data <- response[["data"]]

  if (is.null(data) || length(data) == 0) {
    return(tibble::tibble(
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

  rows <- lapply(data, function(d) {
    tibble::tibble(
      pedts = pedts_resp,
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
