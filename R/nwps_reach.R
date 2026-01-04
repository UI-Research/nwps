#' Get NWM reach metadata
#'
#' Retrieves metadata for a National Water Model (NWM) reach, including
#' location, available streamflow products, and upstream/downstream routing.
#'
#' @param reach_id Character or numeric. The NWM reach identifier.
#'
#' @return A list containing:
#'   \describe{
#'     \item{metadata}{An sf object (point geometry) with reach_id, name,
#'       latitude, longitude}
#'     \item{streamflow_products}{Character vector of available streamflow
#'       forecast types (e.g., "short_range", "medium_range")}
#'     \item{upstream}{A tibble of upstream reaches with reach_id and
#'       stream_order}
#'     \item{downstream}{A tibble of downstream reaches with reach_id and
#'       stream_order}
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' reach <- nwps_reach("22338099")
#' reach$metadata
#' reach$upstream
#' }
nwps_reach <- function(reach_id) {
  reach_id <- as.character(reach_id)

  if (reach_id == "" || is.na(reach_id)) {
    cli::cli_abort("{.arg reach_id} must be a non-empty string.")
  }

  response <- nwps_request(paste0("/reaches/", reach_id))

  metadata_df <- tibble::tibble(
    reach_id = response[["reachId"]] %||% NA_character_,
    name = response[["name"]] %||% NA_character_,
    latitude = response[["latitude"]] %||% NA_real_,
    longitude = response[["longitude"]] %||% NA_real_
  )

  metadata_sf <- as_sf_points(metadata_df)

  streamflow_products <- unlist(response[["streamflow"]]) %||% character()

  upstream <- parse_route_reaches(response[["route"]][["upstream"]])
  downstream <- parse_route_reaches(response[["route"]][["downstream"]])

  list(
    metadata = metadata_sf,
    streamflow_products = streamflow_products,
    upstream = upstream,
    downstream = downstream
  )
}

#' Parse route reach list
#'
#' @param reaches List. Array of reach objects with reachId and streamOrder.
#'
#' @return A tibble with reach_id and stream_order columns.
#'
#' @noRd
parse_route_reaches <- function(reaches) {
  if (is.null(reaches) || length(reaches) == 0) {
    return(tibble::tibble(
      reach_id = character(),
      stream_order = character()
    ))
  }

  lapply(reaches, function(r) {
    tibble::tibble(
      reach_id = r[["reachId"]] %||% NA_character_,
      stream_order = r[["streamOrder"]] %||% NA_character_
    )
  }) |> dplyr::bind_rows()
}
