#' axR: Device Discovery, Status, Settings, and Data Download for Axivity Devices
#'
#' Talks to Axivity AX3/AX6 accelerometer devices: discovery, status
#' (battery, self-test, memory health, accelerometer, RTC, LED, lock,
#' ECC), settings (delays, session ID, metadata, accelerometer config,
#' erase), and data download.
#'
#' axR is a "dumb pipe" package: it talks to the device and moves bytes
#' around, but does not parse `.cwa` file contents. Parsing is left to
#' downstream packages such as \pkg{mrpheus} and \pkg{zeitR}.
#'
#' @section Implementation:
#' Rather than reimplementing the Axivity serial protocol directly, axR
#' wraps the Open Movement Project's OMAPI C library (vendored in
#' `src/omapi`, BSD 2-clause, Newcastle University -- see
#' `src/omapi/LICENSE.TXT`). OMAPI is the same library behind Axivity's
#' own OmGui software, and includes maintained, platform-specific device
#' discovery (IOKit/DiskArbitration on macOS, SetupAPI on Windows, udev on
#' Linux) rather than a hand-rolled equivalent.
#'
#' The OMAPI session is started when axR is loaded (`OmStartup()` in
#' `.onLoad()`) and shut down when it's unloaded (`OmShutdown()` in
#' `.onUnload()`) -- there's no separate `axivity_open()`/`close()` step.
#' Every exported function takes a `device_id`, obtained from
#' [axivity_discover()].
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom Rcpp sourceCpp
#' @useDynLib axR, .registration = TRUE
## usethis namespace: end
NULL
