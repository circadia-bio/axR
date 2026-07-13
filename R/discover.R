#' Discover connected Axivity devices
#'
#' Wraps OMAPI's `OmGetDeviceIds()` plus a handful of per-device status
#' calls into a single data frame. Unlike serial-port probing, this uses
#' OMAPI's own device discovery -- including its platform-specific finder
#' (IOKit/DiskArbitration on macOS, SetupAPI on Windows, udev on Linux) --
#' so it should behave the same way OmGui does on the same machine.
#'
#' @return A data frame with one row per connected device: `device_id`,
#'   `serial`, `port`, `path`, `firmware_version`, `hardware_version`,
#'   `battery_level`. Zero rows if no devices are connected.
#'
#' @export
axivity_discover <- function() {
  ids <- axR_omapi_get_device_ids_cpp()

  if (length(ids) == 0) {
    return(data.frame(
      device_id = integer(0), serial = character(0), port = character(0),
      path = character(0), firmware_version = integer(0),
      hardware_version = integer(0), battery_level = integer(0),
      stringsAsFactors = FALSE
    ))
  }

  rows <- lapply(ids, function(id) {
    info <- axR_omapi_get_device_info_cpp(id)
    data.frame(
      device_id = info$device_id, serial = info$serial, port = info$port,
      path = info$path, firmware_version = info$firmware_version,
      hardware_version = info$hardware_version, battery_level = info$battery_level,
      stringsAsFactors = FALSE
    )
  })

  do.call(rbind, rows)
}

#' Enable OMAPI's internal debug log
#'
#' A diagnostic escape hatch for when [axivity_discover()] isn't finding a
#' device you expect it to. OMAPI logs internally via its own `OmLog()`,
#' but axR's default log target is `NULL` (so compiled code doesn't write
#' to stderr unprompted -- see `NEWS.md`). This re-enables it.
#'
#' **Important:** this only controls where log lines go. Whether
#' anything is logged *at all* is controlled by OMAPI's debug level,
#' which is read from the `OMDEBUG` environment variable once, at
#' `OmStartup()` time -- i.e. before `library(axR)` runs. If you're not
#' seeing log output after calling this, set `OMDEBUG` (e.g.
#' `Sys.setenv(OMDEBUG = "3")`) *before* loading axR, in a fresh R
#' session, then call this function and retry.
#'
#' @param file Character path to a log file, or `NULL` (default) to log
#'   to stderr. A file is more reliable for diagnostic purposes: OMAPI's
#'   discovery thread logs from a background pthread, and raw stderr
#'   writes from a non-R thread don't always reach the R console/terminal
#'   depending on the frontend -- a file sidesteps that ambiguity.
#' @return Invisibly, the OMAPI status code (negative indicates failure,
#'   e.g. the file couldn't be opened).
#' @export
axivity_enable_debug_log <- function(file = NULL) {
  if (is.null(file)) {
    invisible(axR_omapi_set_log_stream_cpp(2L))  # 2 = stderr
  } else {
    invisible(axR_omapi_set_log_file_cpp(path.expand(file)))
  }
}
