#' Get gauge stage-to-flow ratings
#'
#' Retrieves the stage-to-flow rating curve data for a gauge. Rating curves
#' define the relationship between water level (stage) and discharge (flow).
#'
#' @param identifier Character. Gauge LID (e.g., "PTTP1") or USGS ID.
#' @param limit Integer. Maximum number of rating points to return.
#'   Default is 10000.
#' @param sort Character. Sort order by stage value. One of `"ASC"` (ascending,
#'   default) or `"DESC"` (descending).
#' @param only_tenths Logical. If `TRUE`, filter results to only include
#'   stage values at tenths-of-foot increments. Default is `FALSE`.
#'
#' @return A tibble with columns:
#'   \describe{
#'     \item{stage}{Water level value}
#'     \item{stage_units}{Units for stage (typically "ft")}
#'     \item{flow}{Discharge value corresponding to the stage}
#'     \item{flow_units}{Units for flow (typically "cfs")}
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get rating curve for a gauge
#' ratings <- nwps_gauge_ratings("PTTP1")
#'
#' # Get only tenths-of-foot increments, sorted descending
#' ratings <- nwps_gauge_ratings("PTTP1", only_tenths = TRUE, sort = "DESC")
#' }
nwps_gauge_ratings <- function(identifier,
                               limit = 10000,
                               sort = c("ASC", "DESC"),
                               only_tenths = FALSE) {
  identifier <- as.character(identifier)
  sort <- match.arg(sort)

  if (identifier == "" || is.na(identifier)) {
    cli::cli_abort("{.arg identifier} must be a non-empty string.")
  }

  if (!is.numeric(limit) || limit < 1) {
    cli::cli_abort("{.arg limit} must be a positive integer.")
  }

  if (!is.logical(only_tenths)) {
    cli::cli_abort("{.arg only_tenths} must be TRUE or FALSE.")
  }

  query <- list(
    limit = as.integer(limit),
    sort = sort,
    onlyTenths = tolower(as.character(only_tenths))
  )

  response <- nwps_request(
    paste0("/gauges/", identifier, "/ratings"),
    query = query
  )

  stage_units <- response[["stageUnits"]] %||% NA_character_
  flow_units <- response[["flowUnits"]] %||% NA_character_
  data <- response[["data"]]

  if (is.null(data) || length(data) == 0) {
    return(tibble::tibble(
      stage = double(),
      stage_units = character(),
      flow = double(),
      flow_units = character()
    ))
  }

  ratings <- lapply(data, function(d) {
    tibble::tibble(
      stage = d[["stage"]] %||% NA_real_,
      stage_units = stage_units,
      flow = d[["flow"]] %||% NA_real_,
      flow_units = flow_units
    )
  }) |> dplyr::bind_rows()

  ratings
}
