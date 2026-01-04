#' Get gauge metadata
#'
#' Retrieves detailed metadata for a single NWPS gauge by its identifier.
#'
#' @param identifier Character. Gauge LID (e.g., "ANAD2") or USGS ID
#'   (e.g., "01651750").
#'
#' @return A list containing gauge metadata with the following components:
#'   \describe{
#'     \item{metadata}{An sf object (point geometry) with basic gauge information
#'       (lid, usgsId, reachId, name, description, latitude, longitude,
#'       timeZone, county)}
#'     \item{organizations}{A tibble with RFC, WFO, and state information}
#'     \item{pedts}{A tibble with SHEF codes for observed and forecast data}
#'     \item{status}{A tibble with current observed and forecast status}
#'     \item{flood_categories}{A tibble with flood stage/flow thresholds}
#'     \item{flood_crests}{A tibble with historic and recent flood crests}
#'     \item{flood_impacts}{A tibble with stage-based impact statements}
#'     \item{low_waters}{A tibble with historic low water records}
#'     \item{datums}{A tibble with vertical and horizontal datum information
#'       if present, NULL otherwise}
#'     \item{images}{A list with URLs for hydrograph and other images}
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' gauge <- nwps_gauge("ANAD2")
#' gauge$metadata
#' gauge$flood_categories
#' }
nwps_gauge <- function(identifier) {
  identifier <- as.character(identifier)

  if (identifier == "" || is.na(identifier)) {
    cli::cli_abort("{.arg identifier} must be a non-empty string.")
  }

  response <- nwps_request(paste0("/gauges/", identifier))

  result <- list(
    metadata = parse_gauge_metadata(response),
    organizations = parse_gauge_organizations(response),
    pedts = parse_gauge_pedts(response),
    status = parse_gauge_status(response),
    flood_categories = parse_flood_categories(response),
    flood_crests = parse_flood_crests(response),
    flood_impacts = parse_flood_impacts(response),
    low_waters = parse_low_waters(response),
    datums = parse_datums(response),
    images = parse_images(response)
  )

  result
}

#' @noRd
parse_gauge_metadata <- function(response) {
  metadata_df <- tibble::tibble(
    lid = response[["lid"]] %||% NA_character_,
    usgs_id = response[["usgsId"]] %||% NA_character_,
    reach_id = response[["reachId"]] %||% NA_character_,
    name = response[["name"]] %||% NA_character_,
    description = response[["description"]] %||% NA_character_,
    latitude = response[["latitude"]] %||% NA_real_,
    longitude = response[["longitude"]] %||% NA_real_,
    time_zone = response[["timeZone"]] %||% NA_character_,
    county = response[["county"]] %||% NA_character_,
    in_service = response[["inService"]][["enabled"]] %||% NA,
    in_service_message = response[["inService"]][["message"]] %||% NA_character_,
    forecast_reliability = response[["forecastReliability"]] %||% NA_character_
  )

  as_sf_points(metadata_df)
}

#' @noRd
parse_gauge_organizations <- function(response) {
  tibble::tibble(
    rfc_abbreviation = response[["rfc"]][["abbreviation"]] %||% NA_character_,
    rfc_name = response[["rfc"]][["name"]] %||% NA_character_,
    wfo_abbreviation = response[["wfo"]][["abbreviation"]] %||% NA_character_,
    wfo_name = response[["wfo"]][["name"]] %||% NA_character_,
    state_abbreviation = response[["state"]][["abbreviation"]] %||% NA_character_,
    state_name = response[["state"]][["name"]] %||% NA_character_
  )
}

#' @noRd
parse_gauge_pedts <- function(response) {
  tibble::tibble(
    observed = response[["pedts"]][["observed"]] %||% NA_character_,
    forecast = response[["pedts"]][["forecast"]] %||% NA_character_
  )
}

#' @noRd
parse_gauge_status <- function(response) {
  obs <- response[["status"]][["observed"]]
  fcst <- response[["status"]][["forecast"]]

  tibble::tibble(
    type = c("observed", "forecast"),
    primary = c(
      obs[["primary"]] %||% NA_real_,
      fcst[["primary"]] %||% NA_real_
    ),
    primary_unit = c(
      obs[["primaryUnit"]] %||% NA_character_,
      fcst[["primaryUnit"]] %||% NA_character_
    ),
    secondary = c(
      obs[["secondary"]] %||% NA_real_,
      fcst[["secondary"]] %||% NA_real_
    ),
    secondary_unit = c(
      obs[["secondaryUnit"]] %||% NA_character_,
      fcst[["secondaryUnit"]] %||% NA_character_
    ),
    flood_category = c(
      obs[["floodCategory"]] %||% NA_character_,
      fcst[["floodCategory"]] %||% NA_character_
    ),
    valid_time = c(
      parse_timestamp(obs[["validTime"]]),
      parse_timestamp(fcst[["validTime"]])
    )
  )
}

#' @noRd
parse_flood_categories <- function(response) {
  flood <- response[["flood"]]
  if (is.null(flood)) return(tibble::tibble())

  categories <- flood[["categories"]]
  if (is.null(categories)) return(tibble::tibble())

  stage_units <- flood[["stageUnits"]] %||% NA_character_
  flow_units <- flood[["flowUnits"]] %||% NA_character_

  cat_names <- c("action", "minor", "moderate", "major")
  rows <- lapply(cat_names, function(cat) {
    cat_data <- categories[[cat]]
    if (is.null(cat_data)) return(NULL)
    tibble::tibble(
      category = cat,
      stage = cat_data[["stage"]] %||% NA_real_,
      stage_units = stage_units,
      flow = cat_data[["flow"]] %||% NA_real_,
      flow_units = flow_units
    )
  })

  dplyr::bind_rows(rows)
}

#' @noRd
parse_flood_crests <- function(response) {
  crests <- response[["flood"]][["crests"]]
  if (is.null(crests)) return(tibble::tibble())

  parse_crest_list <- function(crest_list, crest_type) {
    if (is.null(crest_list) || length(crest_list) == 0) return(NULL)
    lapply(crest_list, function(c) {
      tibble::tibble(
        type = crest_type,
        occurred_time = parse_timestamp(c[["occurredTime"]]),
        stage = c[["stage"]] %||% NA_real_,
        flow = c[["flow"]] %||% NA_real_,
        preliminary = c[["preliminary"]] %||% NA,
        old_datum = c[["olddatum"]] %||% NA
      )
    }) |> dplyr::bind_rows()
  }

  historic <- parse_crest_list(crests[["historic"]], "historic")
  recent <- parse_crest_list(crests[["recent"]], "recent")

  dplyr::bind_rows(historic, recent)
}

#' @noRd
parse_flood_impacts <- function(response) {
  impacts <- response[["flood"]][["impacts"]]
  if (is.null(impacts) || length(impacts) == 0) return(tibble::tibble())

  lapply(impacts, function(i) {
    tibble::tibble(
      stage = i[["stage"]] %||% NA_real_,
      statement = i[["statement"]] %||% NA_character_
    )
  }) |> dplyr::bind_rows()
}

#' @noRd
parse_low_waters <- function(response) {
  low_waters <- response[["flood"]][["lowWaters"]]
  if (is.null(low_waters) || length(low_waters) == 0) return(tibble::tibble())

  lapply(low_waters, function(lw) {
    tibble::tibble(
      occurred_time = parse_timestamp(lw[["occurredTime"]]),
      stage = lw[["stage"]] %||% NA_real_,
      flow = lw[["flow"]] %||% NA_real_,
      statement = lw[["statement"]] %||% NA_character_
    )
  }) |> dplyr::bind_rows()
}

#' @noRd
parse_datums <- function(response) {
  datums <- response[["datums"]]
  if (is.null(datums)) return(NULL)

  tibble::tibble(
    vertical = datums[["vertical"]] %||% NA_character_,
    horizontal = datums[["horizontal"]] %||% NA_character_,
    notes = datums[["notes"]] %||% NA_character_
  )
}

#' @noRd
parse_images <- function(response) {
  images <- response[["images"]]
  if (is.null(images)) return(list())

  list(
    probability = images[["probability"]] %||% NA_character_,
    hydrograph_default = images[["hydrograph"]][["default"]] %||% NA_character_,
    hydrograph_floodcat = images[["hydrograph"]][["floodcat"]] %||% NA_character_,
    photos = images[["photos"]] %||% list()
  )
}
