#' axR: Device Communication and .cwa File Reading for Axivity Devices
#'
#' Talks to Axivity AX3/AX6 accelerometer devices: discovery, status
#' (battery, self-test, memory health, accelerometer, RTC, LED, lock,
#' ECC), settings (delays, session ID, metadata, accelerometer config,
#' erase), data download, and reading recorded `.cwa`/AX6 binary files
#' ([axivity_read_cwa()]).
#'
#' axR was originally scoped as a "dumb pipe" -- talk to the device, move
#' bytes, leave file parsing to downstream packages. [axivity_read_cwa()]
#' is a deliberate exception: OMAPI already ships a complete binary file
#' reader (`omapi-reader.c`), and wrapping it directly is simpler and
#' more consistent than reimplementing the same format a second time in
#' \pkg{zeitR} from a different reference pipeline. axR does not do any
#' higher-level actigraphy analysis on the parsed data (sleep detection,
#' non-wear detection, etc.) -- that's still \pkg{zeitR}'s job, downstream
#' of the tibble this returns.
#'
#' @section Implementation:
#' Rather than reimplementing the Axivity serial protocol or `.cwa`
#' binary format directly, axR wraps the Open Movement Project's OMAPI C
#' library (vendored in `src/omapi`, BSD 2-clause, Newcastle University
#' -- see `src/omapi/LICENSE.TXT`). OMAPI is the same library behind
#' Axivity's own OmGui software, and includes maintained,
#' platform-specific device discovery (IOKit/DiskArbitration on macOS,
#' SetupAPI on Windows, udev on Linux) rather than a hand-rolled
#' equivalent.
#'
#' The OMAPI session is started when axR is loaded (`OmStartup()` in
#' `.onLoad()`) and shut down when it's unloaded (`OmShutdown()` in
#' `.onUnload()`) -- there's no separate `axivity_open()`/`close()` step.
#' Every device-facing function takes a `device_id`, obtained from
#' [axivity_discover()]. [axivity_read_cwa()] and [axivity_copy_data()]
#' are the exceptions -- they work on a file already on disk and don't
#' need a live device connection at all.
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom Rcpp sourceCpp
#' @useDynLib axR, .registration = TRUE
## usethis namespace: end
NULL
