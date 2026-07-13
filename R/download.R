#' Download recorded data off an Axivity device
#'
#' Axivity devices expose recorded `.cwa` files over a standard USB mass
#' storage interface once configured; this copies file(s) off that volume.
#' `axR` does not parse `.cwa` contents — see `mrpheus` or `zeitR` for that.
#'
#' @param device_path Character. Path to the mounted device volume.
#' @param dest_dir Character. Destination directory for downloaded files.
#' @param pattern Character. Regex to filter which files are copied.
#'   Default `"\\.cwa$"`.
#'
#' @return Character vector of destination file paths.
#'
#' @export
axivity_download <- function(device_path, dest_dir, pattern = "\\.cwa$") {
  .NotYetImplemented()
}
