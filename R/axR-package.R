#' axR: Interfacing and Retrieving Data from Accelerometer Devices
#'
#' Talks to Axivity AX3/AX6 accelerometer devices: discovery, status
#' (battery, self-test, memory health, accelerometer, RTC, LED, lock,
#' ECC), settings (delays, session ID, metadata, accelerometer config,
#' erase), data download, and reading recorded `.cwa`/AX6 binary files
#' ([axivity_read_cwa()]). Also reads Condor Instruments ActTrust `.txt`
#' actigraphy exports ([read_acttrust()]) into the same tidy epoch shape,
#' as a device-agnostic actigraphy import layer.
#'
#' axR was originally scoped as a "dumb pipe" -- talk to the device, move
#' bytes, leave file parsing to downstream packages. [axivity_read_cwa()]
#' and [read_acttrust()] are deliberate exceptions: OMAPI already ships a
#' complete binary file reader (`omapi-reader.c`), and ActTrust's `.txt`
#' export is a plain, well-specified text format -- wrapping/parsing both
#' directly is simpler and more consistent than reimplementing either
#' format a second time in \pkg{zeitR} from a different reference
#' pipeline. axR does not do any higher-level actigraphy analysis on the
#' parsed data (sleep detection, non-wear detection, etc.) -- that's
#' still \pkg{zeitR}'s job, downstream of the tibbles these functions
#' return.
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
#' [axivity_discover()]. [axivity_read_cwa()], [read_acttrust()], and
#' [axivity_copy_data()] are the exceptions -- they work on a file
#' already on disk and don't need a live device connection at all.
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom Rcpp sourceCpp
#' @useDynLib axR, .registration = TRUE
## usethis namespace: end
NULL
