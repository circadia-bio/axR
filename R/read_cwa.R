#' Read a .cwa/AX6 binary file into a tibble
#'
#' Uses OMAPI's own binary file reader (`omapi-reader.c`, vendored from
#' libomapi) to parse a `.cwa`/AX6 recording directly, rather than
#' reimplementing the binary format from scratch. Returns one row per
#' sample -- ready to hand to `zeitR`, or any other downstream actigraphy
#' analysis.
#'
#' Unlike the rest of axR, this function doesn't talk to a live device at
#' all -- it works on a file already on disk (e.g. one retrieved with
#' [axivity_copy_data()] or [axivity_download()]), and doesn't require
#' [axivity_discover()] to have found anything.
#'
#' @param path Character. Path to a `.cwa`/AX6 file.
#'
#' @return A tibble (or plain data frame, if the `tibble` package isn't
#'   installed) with one row per sample:
#'   \describe{
#'     \item{timestamp}{`POSIXct`, UTC, with sub-second precision}
#'     \item{x, y, z}{Accelerometer readings, in g}
#'     \item{gx, gy, gz}{Gyroscope readings, raw units (only present if
#'       the recording has a gyroscope, e.g. AX6 in GA/GAM mode)}
#'     \item{mx, my, mz}{Magnetometer readings, raw units (only present
#'       if the recording has a magnetometer, e.g. AX6 in GAM mode)}
#'     \item{light}{Raw light sensor reading}
#'     \item{temperature_c}{Temperature in degrees Celsius. **Unverified,
#'       possibly wrong** -- OMAPI's conversion (`OM_VALUE_TEMPERATURE_MC`)
#'       hardcodes a formula for one specific temperature sensor chip
#'       (MCP9700); a comment beside it in the vendored source notes an
#'       alternate formula for a different chip (MCP9701), suggesting
#'       this may be hardware/revision-specific. Cross-check against
#'       OmGui's own reading for the same file before relying on this.}
#'     \item{battery_pct}{Battery percentage, at the time of this block}
#'     \item{sample_rate}{Sampling rate in Hz, at the time of this block}
#'   }
#'   with `device_id`, `session_id`, and `metadata` attached as
#'   attributes. `timestamp`, `x`/`y`/`z`, and `device_id` have been
#'   verified correct against a real AX3 file (cross-checked device_id
#'   against `ioreg` and the Axivity config web tool); `temperature_c`
#'   has not.
#'
#' @export
axivity_read_cwa <- function(path) {
  path <- path.expand(path)
  if (!file.exists(path)) {
    stop("File not found: ", path)
  }

  raw <- axR_read_cwa_cpp(path)

  timestamp <- ISOdatetime(raw$year, raw$month, raw$day, raw$hour, raw$minute, raw$second, tz = "UTC") +
    raw$frac / 65536

  out <- data.frame(
    timestamp = timestamp,
    x = raw$x, y = raw$y, z = raw$z,
    stringsAsFactors = FALSE
  )

  if (!is.null(raw$gx)) {
    out$gx <- raw$gx
    out$gy <- raw$gy
    out$gz <- raw$gz
  }
  if (!is.null(raw$mx)) {
    out$mx <- raw$mx
    out$my <- raw$my
    out$mz <- raw$mz
  }

  out$light <- raw$light
  out$temperature_c <- raw$temperature_mc / 1000
  out$battery_pct <- raw$battery_pct
  out$sample_rate <- raw$sample_rate

  attr(out, "device_id") <- raw$device_id
  attr(out, "session_id") <- raw$session_id
  attr(out, "metadata") <- sub("[\\x20\\x00\\xff]*$", "", raw$metadata, perl = TRUE)

  if (requireNamespace("tibble", quietly = TRUE)) {
    out <- tibble::as_tibble(out)
  }

  out
}
