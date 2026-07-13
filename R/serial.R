#' Discover connected Axivity devices
#'
#' Scans candidate serial ports and probes each one with the `ID` command,
#' checking for the Axivity signature in the response (`CWA` for AX3, `AX6`
#' for AX6). This matches devices by protocol handshake rather than by USB
#' vendor/product ID, so it should keep working across firmware/driver
#' versions that might change the reported USB descriptors.
#'
#' @param baud Integer. Baud rate to use for the probe. Default `115200`.
#' @param timeout_ms Integer. How long to wait for a response from each
#'   candidate port, in milliseconds. Default `500`.
#'
#' @return A data frame with one row per device found, with columns `port`,
#'   `type` (`"CWA"` for AX3, `"AX6"` for AX6), `hardware_version`,
#'   `firmware_version`, and `device_id`. Zero rows if none are found.
#'
#' @export
axivity_discover <- function(baud = 115200L, timeout_ms = 500L) {
  candidates <- .candidate_ports()

  rows <- lapply(candidates, function(port) {
    handle <- tryCatch(axivity_open(port, baud = baud), error = function(e) NULL)
    if (is.null(handle)) return(NULL)
    on.exit(axivity_close(handle), add = TRUE)

    response <- tryCatch(
      axivity_send_command(handle, "ID", timeout_ms = timeout_ms),
      error = function(e) ""
    )

    parsed <- .parse_id_response(response)
    if (is.null(parsed)) return(NULL)

    data.frame(
      port = port,
      type = parsed$type,
      hardware_version = parsed$hardware_version,
      firmware_version = parsed$firmware_version,
      device_id = parsed$device_id,
      stringsAsFactors = FALSE
    )
  })

  rows <- rows[!vapply(rows, is.null, logical(1))]

  if (length(rows) == 0) {
    return(data.frame(
      port = character(0),
      type = character(0),
      hardware_version = character(0),
      firmware_version = character(0),
      device_id = character(0),
      stringsAsFactors = FALSE
    ))
  }

  do.call(rbind, rows)
}

# Candidate serial ports to probe. On POSIX this globs the usual USB CDC
# device paths; on Windows there's no direct equivalent to globbing, so a
# fixed COM1-COM40 range is probed instead (revisit with SetupAPI-based
# enumeration if this range proves too narrow in practice).
.candidate_ports <- function() {
  if (.Platform$OS.type == "windows") {
    return(paste0("COM", 1:40))
  }
  unique(c(
    Sys.glob("/dev/tty.usbmodem*"),
    Sys.glob("/dev/cu.usbmodem*"),
    Sys.glob("/dev/ttyACM*"),
    Sys.glob("/dev/ttyUSB*")
  ))
}

# Parses a response to the `ID` command: "ID=<type>,<hardwareVer>,<firmwareVer>,<deviceId>"
# Returns NULL if the response doesn't match (i.e. not an Axivity device).
.parse_id_response <- function(response) {
  line <- trimws(response)
  if (!grepl("^ID=", line)) return(NULL)
  value <- sub("^ID=", "", line)
  parts <- strsplit(value, ",")[[1]]
  if (length(parts) < 4) return(NULL)
  if (!parts[1] %in% c("CWA", "AX6")) return(NULL)
  list(
    type = parts[1],
    hardware_version = parts[2],
    firmware_version = parts[3],
    device_id = parts[4]
  )
}

#' Open a serial connection to an Axivity device
#'
#' @param port Character. The serial port / device path
#'   (e.g. `"/dev/tty.usbmodemXXXX"` on macOS, `"/dev/ttyACM0"` on Linux, or
#'   `"COM3"` on Windows).
#' @param baud Integer. Baud rate. The device is a USB CDC virtual serial
#'   port, so the exact value is largely conventional; `115200` matches the
#'   rate used by Axivity's own OmGui software.
#'
#' @return An object of class `"axR_connection"`, to be passed to
#'   [axivity_send_command()], [axivity_reset()], and [axivity_close()].
#'
#' @export
axivity_open <- function(port, baud = 115200L) {
  xptr <- axR_serial_open_cpp(port, as.integer(baud))
  structure(list(xptr = xptr, port = port), class = "axR_connection")
}

#' Close a serial connection to an Axivity device
#'
#' @param handle An `"axR_connection"` object returned by [axivity_open()].
#'
#' @export
axivity_close <- function(handle) {
  stopifnot(inherits(handle, "axR_connection"))
  axR_serial_close_cpp(handle$xptr)
  invisible(NULL)
}

#' Send a raw command to an Axivity device
#'
#' Sends a plain-text command line following the Open Movement serial
#' command protocol (commands/responses are 7-bit ASCII, CR/LF terminated)
#' and returns the device's response.
#'
#' @param handle An `"axR_connection"` object returned by [axivity_open()].
#' @param command Character. The command string to send, e.g. `"ID"`,
#'   `"TIME"`, `"SESSION"`.
#' @param timeout_ms Integer. How long to wait for a response, in
#'   milliseconds. Default `2000`.
#'
#' @return Character. The device's raw response line (e.g. `"ID=CWA,..."`).
#'   Only the first line of the response is captured; multi-line output
#'   (e.g. from `STREAM`) is not supported by this function.
#'
#' @export
axivity_send_command <- function(handle, command, timeout_ms = 2000L) {
  stopifnot(inherits(handle, "axR_connection"))
  axR_serial_write_cmd_cpp(handle$xptr, command, as.integer(timeout_ms))
}

#' Reset (format) an Axivity device
#'
#' Sends the device's `FORMAT` command, following the Open Movement
#' protocol: `FORMAT {Q|W}[C]`, where `Q` performs a quick format
#' (filesystem recreated) and `W` thoroughly wipes the NAND memory. The
#' optional `commit` flag appends `C`, which also rewrites the data file
#' header afterwards.
#'
#' During formatting the device's USB mass storage volume briefly
#' disappears and re-appears to the operating system, so this can take
#' noticeably longer than other commands -- `timeout_ms` defaults higher
#' than [axivity_send_command()]'s.
#'
#' @param handle An `"axR_connection"` object returned by [axivity_open()].
#' @param full Logical. If `TRUE`, perform a full NAND wipe (`FORMAT W`)
#'   instead of a quick format (`FORMAT Q`). Default `FALSE`.
#' @param commit Logical. If `TRUE`, also commit/rewrite the data file
#'   header afterwards (`FORMAT ...C`). Default `FALSE`.
#' @param timeout_ms Integer. How long to wait for a response, in
#'   milliseconds. Default `15000` (formatting -- especially a full wipe --
#'   can take much longer than a typical query command).
#'
#' @return Character. The device's raw response.
#'
#' @export
axivity_reset <- function(handle, full = FALSE, commit = FALSE, timeout_ms = 15000L) {
  stopifnot(inherits(handle, "axR_connection"))
  cmd <- paste0("FORMAT ", if (isTRUE(full)) "W" else "Q", if (isTRUE(commit)) "C" else "")
  axivity_send_command(handle, cmd, timeout_ms = timeout_ms)
}
