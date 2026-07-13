#' Discover connected Axivity devices
#'
#' Scans available serial (CDC/COM port) devices for ones matching the
#' Axivity AX3/AX6 vendor/product signature.
#'
#' @return A data frame with one row per device found, with columns such as
#'   `port`, `device_id`, and `model`. Columns are provisional pending
#'   protocol design.
#'
#' @export
axivity_discover <- function() {
  .NotYetImplemented()
}

#' Open a serial connection to an Axivity device
#'
#' @param port Character. The serial port / device path
#'   (e.g. `"/dev/tty.usbmodemXXXX"` on macOS, `"/dev/ttyACM0"` on Linux, or
#'   `"COM3"` on Windows).
#' @param baud Integer. Baud rate. Default TBD pending protocol design.
#'
#' @return An opaque connection handle to be passed to
#'   [axivity_send_command()], [axivity_reset()], and [axivity_close()].
#'
#' @export
axivity_open <- function(port, baud = 115200L) {
  .NotYetImplemented()
}

#' Close a serial connection to an Axivity device
#'
#' @param handle A connection handle returned by [axivity_open()].
#'
#' @export
axivity_close <- function(handle) {
  .NotYetImplemented()
}

#' Send a raw command to an Axivity device
#'
#' Sends a plain-text command line following the Open Movement serial
#' command protocol and returns the device's response.
#'
#' @param handle A connection handle returned by [axivity_open()].
#' @param command Character. The command string to send.
#'
#' @return Character. The device's response.
#'
#' @export
axivity_send_command <- function(handle, command) {
  .NotYetImplemented()
}

#' Reset (format) an Axivity device
#'
#' Sends the device format command, clearing recorded data. Corresponds to
#' the `FORMAT` (quick) or `FORMAT W` (full wipe) commands in the Open
#' Movement protocol.
#'
#' @param handle A connection handle returned by [axivity_open()].
#' @param full Logical. If `TRUE`, perform a full NAND wipe (`FORMAT W`)
#'   instead of a quick format. Default `FALSE`.
#'
#' @export
axivity_reset <- function(handle, full = FALSE) {
  .NotYetImplemented()
}
