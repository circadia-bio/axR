#' axR: Serial Communication and Data Retrieval for Axivity Devices
#'
#' Serial (CDC/COM port) communication with Axivity AX3/AX6 accelerometer
#' devices for device discovery, configuration, and reset, plus retrieval of
#' recorded data over the device's USB mass storage interface.
#'
#' axR is a "dumb pipe" package: it talks to the device and moves bytes
#' around, but does not parse `.cwa` file contents. Parsing is left to
#' downstream packages such as \pkg{mrpheus} and \pkg{zeitR}.
#'
#' @section Serial protocol:
#' Commands are sent as plain-text lines over the device's virtual COM port,
#' following the documented Open Movement command protocol. On POSIX systems
#' (macOS/Linux) the port is opened via `termios.h`; on Windows via the
#' `kernel32` Win32 API (`CreateFile`/`SetCommState`/`SetCommTimeouts`).
#'
#' @section Data retrieval:
#' Once configured, Axivity devices expose recorded `.cwa` files over a
#' standard USB mass storage interface. Downloading data is a plain file
#' copy; no special protocol is needed for this step.
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom Rcpp sourceCpp
## usethis namespace: end
NULL
