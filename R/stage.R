#' Stage an Axivity device for deployment
#'
#' Configures a connected Axivity device end-to-end for a participant
#' deployment: accelerometer settings, deployment window (delays),
#' session ID, and metadata, then commits everything with a reset so
#' the staged settings take full effect.
#'
#' @param device_id Character. Device identifier from `axivity_discover()`.
#' @param start POSIXct. Deployment start time. Use `-Inf` for "always".
#' @param stop POSIXct. Deployment stop time. Use `Inf` for "never".
#'   Ignored if `duration` is supplied.
#' @param duration Optional. A `difftime` (or numeric, in seconds) giving
#'   how long after `start` the deployment should run. Overrides `stop`.
#' @param session_id Integer. Session identifier for this deployment.
#' @param metadata Character. Free-text metadata (e.g. participant ID,
#'   study label) written to the device.
#' @param rate Numeric. Accelerometer sampling rate in Hz. Default 100.
#' @param range Numeric. Accelerometer range in g. Default 8.
#' @param reset_level Character. Reset level for `axivity_reset()` once
#'   settings are staged. One of `"delete"`, `"quickformat"` (default),
#'   or `"wipe"`. `"none"` is deliberately not permitted here.
#'
#' @return Invisibly, a list of the settings that were written.
#' @export
axivity_stage_device <- function(device_id,
                                  start,
                                  stop = Inf,
                                  duration = NULL,
                                  session_id,
                                  metadata = "",
                                  rate = 100,
                                  range = 8,
                                  reset_level = "quickformat") {

  if (!is.null(duration)) {
    if (is.numeric(duration)) duration <- as.difftime(duration, units = "secs")
    stop <- start + duration
  }

  if (identical(reset_level, "none")) {
    stop(
      "reset_level = \"none\" is not supported by axivity_stage_device() -- ",
      "it would leave staged settings only partially committed. Call ",
      "axivity_set_delays()/axivity_set_session_id()/axivity_set_metadata()/",
      "axivity_set_accel_config() individually and axivity_reset() yourself ",
      "if you need that level of control."
    )
  }

  axivity_set_accel_config(device_id, rate = rate, range = range)
  axivity_set_delays(device_id, start = start, stop = stop)
  axivity_set_session_id(device_id, session_id)
  axivity_set_metadata(device_id, metadata)

  axivity_reset(device_id, level = reset_level)

  invisible(list(
    start = start, stop = stop, session_id = session_id,
    metadata = metadata, rate = rate, range = range,
    reset_level = reset_level
  ))
}
