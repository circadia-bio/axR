#' Get or set an Axivity device's delayed activation window
#'
#' @param device_id Integer device ID, as returned by [axivity_discover()].
#' @return `axivity_get_delays()` returns a list with `start` and `stop`,
#'   each either a `POSIXct`, `-Inf` (OMAPI's "always"/zero sentinel), or
#'   `Inf` (OMAPI's "never"/infinite sentinel).
#' @export
axivity_get_delays <- function(device_id) {
  r <- .om_check(axR_omapi_get_delays_cpp(device_id))
  decode <- function(is_zero, is_infinite, raw) {
    if (is_zero) return(-Inf)
    if (is_infinite) return(Inf)
    raw  # already checked against the sentinels; a real timestamp would need re-querying for components
  }
  list(
    start = decode(r$start_is_zero, r$start_is_infinite, r$start_raw),
    stop = decode(r$stop_is_zero, r$stop_is_infinite, r$stop_raw)
  )
}

#' @param start,stop Each either a `POSIXct` (or coercible), `-Inf` (always
#'   record from now / OMAPI's zero sentinel), or `Inf` (never record /
#'   OMAPI's infinite sentinel).
#' @rdname axivity_get_delays
#' @export
axivity_set_delays <- function(device_id, start, stop) {
  encode <- function(x) {
    if (identical(x, -Inf)) return(list(zero = TRUE, infinite = FALSE, parts = as.POSIXlt(0, tz = "UTC")))
    if (identical(x, Inf)) return(list(zero = FALSE, infinite = TRUE, parts = as.POSIXlt(0, tz = "UTC")))
    list(zero = FALSE, infinite = FALSE, parts = as.POSIXlt(as.POSIXct(x, tz = "UTC"), tz = "UTC"))
  }
  s <- encode(start); e <- encode(stop)
  .om_check(axR_omapi_set_delays_cpp(
    device_id,
    s$zero, s$infinite, s$parts$year + 1900, s$parts$mon + 1, s$parts$mday, s$parts$hour, s$parts$min, as.integer(s$parts$sec),
    e$zero, e$infinite, e$parts$year + 1900, e$parts$mon + 1, e$parts$mday, e$parts$hour, e$parts$min, as.integer(e$parts$sec)
  ))
  invisible(NULL)
}

#' Get or set an Axivity device's session identifier
#'
#' @param device_id Integer device ID, as returned by [axivity_discover()].
#' @return `axivity_get_session_id()` returns a numeric (session IDs can
#'   exceed R's 32-bit integer range).
#' @export
axivity_get_session_id <- function(device_id) {
  .om_check(axR_omapi_get_session_id_cpp(device_id))$session_id
}

#' @param session_id A value to set as the session ID.
#' @rdname axivity_get_session_id
#' @export
axivity_set_session_id <- function(device_id, session_id) {
  .om_check(axR_omapi_set_session_id_cpp(device_id, as.double(session_id)))
  invisible(NULL)
}

#' Get or set an Axivity device's metadata scratch buffer
#'
#' @param device_id Integer device ID, as returned by [axivity_discover()].
#' @return `axivity_get_metadata()` returns a character string, trimmed of
#'   trailing padding.
#' @export
axivity_get_metadata <- function(device_id) {
  r <- .om_check(axR_omapi_get_metadata_cpp(device_id))
  sub("[\\x20\\x00\\xff]*$", "", r$metadata, perl = TRUE)
}

#' @param metadata Character. Metadata to store (up to 448 bytes; longer
#'   values are truncated by the device). URL-encode first if it needs to
#'   preserve non-ASCII characters.
#' @rdname axivity_get_metadata
#' @export
axivity_set_metadata <- function(device_id, metadata) {
  .om_check(axR_omapi_set_metadata_cpp(device_id, metadata))
  invisible(NULL)
}

#' Get or set an Axivity device's accelerometer configuration
#'
#' @param device_id Integer device ID, as returned by [axivity_discover()].
#' @return `axivity_get_accel_config()` returns a list with `rate` (Hz)
#'   and `range` (+/- g).
#' @export
axivity_get_accel_config <- function(device_id) {
  r <- .om_check(axR_omapi_get_accel_config_cpp(device_id))
  list(rate = r$rate, range = r$range)
}

#' @param rate Sampling rate in Hz (6 = 6.25, 12 = 12.5, 25, 50, 100,
#'   200, 400, 800, 1600, 3200). Negative = low-power mode.
#' @param range Sampling range in +/- G (2, 4, 8, 16).
#' @rdname axivity_get_accel_config
#' @export
axivity_set_accel_config <- function(device_id, rate, range) {
  .om_check(axR_omapi_set_accel_config_cpp(device_id, as.integer(rate), as.integer(range)))
  invisible(NULL)
}

#' Erase an Axivity device's data storage and commit settings
#'
#' Wraps OMAPI's `OmEraseDataAndCommit()`. Staged settings changes (delays,
#' session ID, metadata, accelerometer config) only take full effect when
#' this is called.
#'
#' @param device_id Integer device ID, as returned by [axivity_discover()].
#' @param level One of `"none"` (commit metadata only, not recommended --
#'   can cause a data/metadata mismatch), `"delete"` (remove and recreate
#'   the data file), `"quickformat"` (recreate the filesystem), or
#'   `"wipe"` (clear all NAND blocks, cleanest but slowest).
#' @export
axivity_reset <- function(device_id, level = "quickformat") {
  levels <- c(none = 0L, delete = 1L, quickformat = 2L, wipe = 3L)
  level <- match.arg(level, names(levels))
  .om_check(axR_omapi_erase_and_commit_cpp(device_id, levels[[level]]))
  invisible(NULL)
}
