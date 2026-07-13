#' Query an Axivity device's battery level and health
#'
#' @param device_id Integer device ID, as returned by [axivity_discover()].
#' @return A list with `level_pct` (0-99% = charging, 100% = full) and
#'   `recharge_cycles` (lower is better).
#' @export
axivity_get_battery <- function(device_id) {
  r <- .om_check(axR_omapi_get_battery_cpp(device_id))
  list(level_pct = r$level_pct, recharge_cycles = r$recharge_cycles)
}

#' Run an Axivity device's built-in self-test
#'
#' @param device_id Integer device ID, as returned by [axivity_discover()].
#' @return A list with `passed` (logical) and `diagnostic_code` (an
#'   opaque, firmware-specific code; `0` means passed).
#' @export
axivity_self_test <- function(device_id) {
  r <- .om_check(axR_omapi_self_test_cpp(device_id))
  list(passed = r$diagnostic_code == 0, diagnostic_code = r$diagnostic_code)
}

#' Query an Axivity device's NAND flash memory health
#'
#' @param device_id Integer device ID, as returned by [axivity_discover()].
#' @return A list with `spare_blocks` (higher is better, `0` = unusable)
#'   and `status` (`"ok"`, `"warning"`, or `"error"`, using OMAPI's
#'   documented thresholds).
#' @export
axivity_get_memory_health <- function(device_id) {
  r <- .om_check(axR_omapi_get_memory_health_cpp(device_id))
  status <- if (r$spare_blocks <= 1) "error" else if (r$spare_blocks <= 8) "warning" else "ok"
  list(spare_blocks = r$spare_blocks, status = status)
}

#' Read an Axivity device's current accelerometer values
#'
#' @param device_id Integer device ID, as returned by [axivity_discover()].
#' @return A named numeric vector `c(x, y, z)` in units of *g*
#'   (raw values are in 1/256 *g*, converted here).
#' @export
axivity_get_accelerometer <- function(device_id) {
  r <- .om_check(axR_omapi_get_accelerometer_cpp(device_id))
  c(x = r$x, y = r$y, z = r$z) / 256
}

#' Get or set an Axivity device's real-time clock
#'
#' @param device_id Integer device ID, as returned by [axivity_discover()].
#' @return `axivity_get_time()` returns a `POSIXct`.
#' @export
axivity_get_time <- function(device_id) {
  r <- .om_check(axR_omapi_get_time_cpp(device_id))
  ISOdatetime(r$year, r$month, r$day, r$hour, r$min, r$sec, tz = "UTC")
}

#' @param time A `POSIXct` (or coercible) date/time to set on the device.
#' @rdname axivity_get_time
#' @export
axivity_set_time <- function(device_id, time) {
  time <- as.POSIXct(time, tz = "UTC")
  parts <- as.POSIXlt(time, tz = "UTC")
  .om_check(axR_omapi_set_time_cpp(
    device_id,
    year = parts$year + 1900, month = parts$mon + 1, day = parts$mday,
    hour = parts$hour, min = parts$min, sec = as.integer(parts$sec)
  ))
  invisible(NULL)
}

#' Set an Axivity device's LED colour
#'
#' @param device_id Integer device ID, as returned by [axivity_discover()].
#' @param colour One of `"auto"` (default device-controlled behaviour),
#'   `"off"`, `"blue"`, `"green"`, `"cyan"`, `"red"`, `"magenta"`,
#'   `"yellow"`, `"white"`.
#' @export
axivity_set_led <- function(device_id, colour) {
  led_codes <- c(auto = -1L, off = 0L, blue = 1L, green = 2L, cyan = 3L,
                 red = 4L, magenta = 5L, yellow = 6L, white = 7L)
  colour <- match.arg(colour, names(led_codes))
  .om_check(axR_omapi_set_led_cpp(device_id, led_codes[[colour]]))
  invisible(NULL)
}

#' Check or set an Axivity device's anti-tamper lock
#'
#' @param device_id Integer device ID, as returned by [axivity_discover()].
#' @return `axivity_is_locked()` returns a list with `locked` and
#'   `has_lock_code` (logicals).
#' @export
axivity_is_locked <- function(device_id) {
  r <- .om_check(axR_omapi_is_locked_cpp(device_id))
  list(locked = r$locked, has_lock_code = r$has_lock_code)
}

#' @param code Integer lock code. `0` = no lock; `0xffff` is reserved.
#' @rdname axivity_is_locked
#' @export
axivity_set_lock <- function(device_id, code) {
  .om_check(axR_omapi_set_lock_cpp(device_id, as.integer(code)))
  invisible(NULL)
}

#' @rdname axivity_is_locked
#' @export
axivity_unlock <- function(device_id, code) {
  .om_check(axR_omapi_unlock_cpp(device_id, as.integer(code)))
  invisible(NULL)
}

#' Get or set an Axivity device's error-correcting code (ECC) flag
#'
#' @param device_id Integer device ID, as returned by [axivity_discover()].
#' @return `axivity_get_ecc()` returns a logical.
#' @export
axivity_get_ecc <- function(device_id) {
  .om_check(axR_omapi_get_ecc_cpp(device_id)) == 1L
}

#' @param enabled Logical. Enable or disable ECC.
#' @rdname axivity_get_ecc
#' @export
axivity_set_ecc <- function(device_id, enabled) {
  .om_check(axR_omapi_set_ecc_cpp(device_id, isTRUE(enabled)))
  invisible(NULL)
}

#' Send a raw command to an Axivity device
#'
#' An escape hatch wrapping OMAPI's `OmCommand()`, for anything not
#' covered by axR's typed functions. Not generally recommended -- OMAPI's
#' own docs note that incorrect use could lead to unspecified behaviour.
#'
#' @param device_id Integer device ID, as returned by [axivity_discover()].
#' @param command Character. The command string to send.
#' @param expected Character. The expected response prefix, or `""` if
#'   not specified.
#' @param timeout_ms Integer. Timeout in milliseconds. Default `2000`.
#' @return Character. The device's raw response.
#' @export
axivity_send_command <- function(device_id, command, expected = "", timeout_ms = 2000L) {
  r <- axR_omapi_command_cpp(device_id, command, expected, as.integer(timeout_ms))
  r$response
}
