#' Get NWM reach streamflow forecasts
#'
#' Retrieves National Water Model streamflow forecasts for a reach. Different
#' forecast series are available with varying time horizons and ensemble
#' configurations.
#'
#' @param reach_id Character or numeric. The NWM reach identifier.
#' @param series Character. The forecast series to retrieve. One of:
#'   \describe{
#'     \item{"analysis_assimilation"}{Analysis and assimilation (recent past)}
#'     \item{"short_range"}{Short-range forecast (0-18 hours)}
#'     \item{"medium_range"}{Medium-range ensemble forecast (0-10 days)}
#'     \item{"medium_range_blend"}{Blended medium-range forecast}
#'     \item{"long_range"}{Long-range ensemble forecast (0-30 days)}
#'   }
#'   Default is `"short_range"`.
#'
#' @return A tibble with columns:
#'   \describe{
#'     \item{reach_id}{NWM reach identifier}
#'     \item{series}{Forecast series name}
#'     \item{member}{Ensemble member name (e.g., "series", "mean", "member1")}
#'     \item{reference_time}{Forecast reference/initialization time (POSIXct)}
#'     \item{valid_time}{Forecast valid time (POSIXct)}
#'     \item{flow}{Streamflow value}
#'     \item{units}{Flow units (typically "ft³/s")}
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get short-range forecast
#' short <- nwps_reach_streamflow("22338099", series = "short_range")
#'
#' # Get medium-range ensemble forecast
#' medium <- nwps_reach_streamflow("22338099", series = "medium_range")
#' }
nwps_reach_streamflow <- function(reach_id,
                                  series = c("short_range",
                                             "analysis_assimilation",
                                             "medium_range",
                                             "medium_range_blend",
                                             "long_range")) {
  reach_id <- as.character(reach_id)
  series <- match.arg(series)

  if (reach_id == "" || is.na(reach_id)) {
    cli::cli_abort("{.arg reach_id} must be a non-empty string.")
  }

  query <- list(series = series)

  response <- nwps_request(
    paste0("/reaches/", reach_id, "/streamflow"),
    query = query
  )

  reach_id_resp <- response[["reach"]][["reachId"]] %||% reach_id

  series_key <- series_to_key(series)
  series_data <- response[[series_key]]

  if (is.null(series_data) || length(series_data) == 0) {
    return(tibble::tibble(
      reach_id = character(),
      series = character(),
      member = character(),
      reference_time = as.POSIXct(character()),
      valid_time = as.POSIXct(character()),
      flow = double(),
      units = character()
    ))
  }

  parse_series_data(series_data, reach_id_resp, series)
}

#' Convert series parameter to API response key
#'
#' @param series Character. The series parameter value.
#'
#' @return Character. The corresponding key in the API response.
#'
#' @noRd
series_to_key <- function(series) {
  switch(series,
    "analysis_assimilation" = "analysisAssimilation",
    "short_range" = "shortRange",
    "medium_range" = "mediumRange",
    "medium_range_blend" = "mediumRangeBlend",
    "long_range" = "longRange"
  )
}

#' Parse streamflow series data
#'
#' Handles both single-series (short_range) and ensemble (medium/long_range)
#' forecast structures.
#'
#' @param series_data List. The series data from API response.
#' @param reach_id Character. The reach identifier.
#' @param series Character. The series name.
#'
#' @return A tibble with parsed streamflow data.
#'
#' @noRd
parse_series_data <- function(series_data, reach_id, series) {
  member_names <- names(series_data)

  if (is.null(member_names) || length(member_names) == 0) {
    return(tibble::tibble(
      reach_id = character(),
      series = character(),
      member = character(),
      reference_time = as.POSIXct(character()),
      valid_time = as.POSIXct(character()),
      flow = double(),
      units = character()
    ))
  }

  all_rows <- lapply(member_names, function(member_name) {
    member_data <- series_data[[member_name]]
    parse_member_data(member_data, reach_id, series, member_name)
  })

  dplyr::bind_rows(all_rows)
}

#' Parse a single ensemble member's data
#'
#' @param member_data List. Data for one ensemble member.
#' @param reach_id Character. The reach identifier.
#' @param series Character. The series name.
#' @param member_name Character. The ensemble member name.
#'
#' @return A tibble with parsed data for this member.
#'
#' @noRd
parse_member_data <- function(member_data, reach_id, series, member_name) {
  if (is.null(member_data) || length(member_data) == 0) {
    return(tibble::tibble(
      reach_id = character(),
      series = character(),
      member = character(),
      reference_time = as.POSIXct(character()),
      valid_time = as.POSIXct(character()),
      flow = double(),
      units = character()
    ))
  }

  reference_time <- parse_timestamp(member_data[["referenceTime"]])
  units <- member_data[["units"]] %||% NA_character_
  data <- member_data[["data"]]

  if (is.null(data) || length(data) == 0) {
    return(tibble::tibble(
      reach_id = reach_id,
      series = series,
      member = member_name,
      reference_time = reference_time,
      valid_time = as.POSIXct(NA),
      flow = NA_real_,
      units = units
    )[0, ])
  }

  rows <- lapply(data, function(d) {
    tibble::tibble(
      reach_id = reach_id,
      series = series,
      member = member_name,
      reference_time = reference_time,
      valid_time = parse_timestamp(d[["validTime"]]),
      flow = d[["flow"]] %||% NA_real_,
      units = units
    )
  })

  dplyr::bind_rows(rows)
}
