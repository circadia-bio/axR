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
