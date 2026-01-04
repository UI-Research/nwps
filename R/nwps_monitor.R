#' Get NWPS system monitoring status
#'
#' Retrieves system health and data status information from the NWPS API,
#' including gauge flood statistics, HML (Hydrologic Message Language)
#' processing stats, and LRO (Long Range Outlook) data status.
#'
#' @return A list containing:
#'   \describe{
#'     \item{gauge_observed}{A tibble with counts of gauges by observed flood
#'       category}
#'     \item{gauge_forecast}{A tibble with counts of gauges by forecast flood
#'       category}
#'     \item{hml_job_queue}{Integer count of jobs in the HML processing queue}
#'     \item{hml_product_counts}{A tibble with HML product counts by time
#'       period}
#'     \item{hml_last_received}{A tibble with timestamps of last HML receipt
#'       by WFO}
#'     \item{lro}{A tibble with current LRO count and interval}
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' status <- nwps_monitor()
#' status$gauge_observed
#' status$hml_product_counts
#' }
nwps_monitor <- function() {
  response <- nwps_request("/monitor")

  gauge_observed <- parse_gauge_counts(response[["gauge"]][["observed"]], "observed")
  gauge_forecast <- parse_gauge_counts(response[["gauge"]][["forecast"]], "forecast")

  hml <- response[["hml"]]
  hml_job_queue <- hml[["jobQueue"]] %||% NA_integer_

  hml_product_counts <- parse_product_counts(hml[["productCounts"]])
  hml_last_received <- parse_last_received(hml[["lastHMLReceived"]])

  lro <- response[["lro"]]
  lro_data <- tibble::tibble(
    current_lros = lro[["currentLros"]] %||% NA_integer_,
    current_interval = lro[["currentInterval"]] %||% NA_character_
  )

  list(
    gauge_observed = gauge_observed,
    gauge_forecast = gauge_forecast,
    hml_job_queue = hml_job_queue,
    hml_product_counts = hml_product_counts,
    hml_last_received = hml_last_received,
    lro = lro_data
  )
}

#' Parse gauge counts by flood category
#'
#' @param counts List. Named list of counts by category.
#' @param type Character. "observed" or "forecast".
#'
#' @return A tibble with category and count columns.
#'
#' @noRd
parse_gauge_counts <- function(counts, type) {
  if (is.null(counts)) {
    return(tibble::tibble(
      type = character(),
      category = character(),
      count = integer()
    ))
  }

  categories <- names(counts)
  rows <- lapply(categories, function(cat) {
    tibble::tibble(
      type = type,
      category = cat,
      count = as.integer(counts[[cat]] %||% 0L)
    )
  })

  dplyr::bind_rows(rows)
}

#' Parse HML product counts
#'
#' @param product_counts List. Named list of counts by time period.
#'
#' @return A tibble with time_period and count columns.
#'
#' @noRd
parse_product_counts <- function(product_counts) {
  if (is.null(product_counts)) {
    return(tibble::tibble(
      time_period = character(),
      count = integer()
    ))
  }

  periods <- names(product_counts)
  rows <- lapply(periods, function(period) {
    tibble::tibble(
      time_period = period,
      count = as.integer(product_counts[[period]] %||% 0L)
    )
  })

  dplyr::bind_rows(rows)
}

#' Parse last HML received timestamps
#'
#' @param last_received List. Contains "fromAny" and "wfo" sub-lists.
#'
#' @return A tibble with wfo and last_received columns.
#'
#' @noRd
parse_last_received <- function(last_received) {
  if (is.null(last_received)) {
    return(tibble::tibble(
      wfo = character(),
      last_received = as.POSIXct(character())
    ))
  }

  wfo_times <- last_received[["wfo"]]
  if (is.null(wfo_times)) {
    return(tibble::tibble(
      wfo = character(),
      last_received = as.POSIXct(character())
    ))
  }

  wfos <- names(wfo_times)
  rows <- lapply(wfos, function(wfo) {
    tibble::tibble(
      wfo = wfo,
      last_received = parse_timestamp(wfo_times[[wfo]])
    )
  })

  result <- dplyr::bind_rows(rows)

  from_any <- parse_timestamp(last_received[["fromAny"]])
  if (!is.na(from_any)) {
    any_row <- tibble::tibble(
      wfo = "_any",
      last_received = from_any
    )
    result <- dplyr::bind_rows(any_row, result)
  }

  result
}
