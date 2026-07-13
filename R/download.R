#' Download recorded data off an Axivity device
#'
#' Axivity devices expose recorded `.cwa` files over a standard USB mass
#' storage interface once configured; this copies file(s) off that volume.
#' `axR` does not parse `.cwa` contents -- see `mrpheus` or `zeitR` for that.
#'
#' @param device_path Character. Path to the mounted device volume
#'   (e.g. `"/Volumes/CWA1234"` on macOS, or a drive letter on Windows).
#' @param dest_dir Character. Destination directory for downloaded files.
#'   Created (recursively) if it doesn't already exist.
#' @param pattern Character. Regex to filter which files are copied,
#'   matched case-insensitively. Default `"\\.cwa$"`.
#' @param overwrite Logical. Overwrite existing files at the destination.
#'   Default `FALSE`.
#'
#' @return Character vector of destination file paths that were
#'   successfully copied.
#'
#' @export
axivity_download <- function(device_path, dest_dir, pattern = "\\.cwa$", overwrite = FALSE) {
  if (!dir.exists(device_path)) {
    stop("device_path does not exist or is not mounted: ", device_path)
  }

  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }

  files <- list.files(device_path, pattern = pattern, ignore.case = TRUE,
                       full.names = TRUE)

  if (length(files) == 0) {
    warning("No files matching '", pattern, "' found at ", device_path)
    return(character(0))
  }

  dest <- file.path(dest_dir, basename(files))
  ok <- file.copy(files, dest, overwrite = overwrite)

  if (!all(ok)) {
    warning("Failed to copy: ", paste(files[!ok], collapse = ", "))
  }

  dest[ok]
}
