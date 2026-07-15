#' Get information about an Axivity device's recorded data
#'
#' @param device_id Integer device ID, as returned by [axivity_discover()].
#' @return A list with `size_bytes`, `filename` (path on the device's own
#'   filesystem, not yet downloaded), `block_size`, `offset_blocks`,
#'   `num_blocks`, and `start`/`end` (`POSIXct`, the time range of the
#'   recorded data).
#' @export
axivity_get_data_info <- function(device_id) {
  r <- .om_check(axR_omapi_get_data_info_cpp(device_id))
  list(
    size_bytes = r$size_bytes,
    filename = r$filename,
    block_size = r$block_size,
    offset_blocks = r$offset_blocks,
    num_blocks = r$num_blocks,
    start = ISOdatetime(r$start_year, r$start_month, r$start_day, r$start_hour, r$start_min, r$start_sec, tz = "UTC"),
    end = ISOdatetime(r$end_year, r$end_month, r$end_day, r$end_hour, r$end_min, r$end_sec, tz = "UTC")
  )
}

# Maps OMAPI's OM_DOWNLOAD_STATUS enum (declared order: NONE, ERROR,
# PROGRESS, COMPLETE, CANCELLED) to a label. Kept as a private lookup
# rather than exported, since download_status()/wait() already return
# the decoded label.
.download_status_labels <- c("none", "error", "progress", "complete", "cancelled")

#' Download recorded data off an Axivity device
#'
#' Wraps OMAPI's `OmBeginDownloading()`, which runs the download on a
#' background thread inside the library. `axR` doesn't parse `.cwa`
#' contents -- see `mrpheus` or `zeitR` for that.
#'
#' @param device_id Integer device ID, as returned by [axivity_discover()].
#' @param dest_file Character. Destination file path (existing files at
#'   this path are truncated).
#' @param offset_blocks Integer. Start offset of the download, in blocks.
#'   Default `0`.
#' @param length_blocks Integer. Length to download, in blocks. Default
#'   `-1` (all).
#' @param blocking Logical. If `TRUE` (default), block until the download
#'   completes, fails, or is cancelled -- equivalent to calling
#'   [axivity_download_wait()] immediately after. If `FALSE`, return as
#'   soon as the download starts; poll with [axivity_download_status()].
#'
#' @return If `blocking = TRUE`, a list with `status` (one of `"complete"`,
#'   `"error"`, `"cancelled"`) and `value` (a diagnostic code if `status`
#'   is `"error"`). If `blocking = FALSE`, invisibly `NULL`.
#'
#' @export
axivity_download <- function(device_id, dest_file, offset_blocks = 0L, length_blocks = -1L, blocking = TRUE) {
  .om_check(axR_omapi_begin_downloading_cpp(device_id, as.integer(offset_blocks), as.integer(length_blocks), dest_file))
  if (!blocking) return(invisible(NULL))
  axivity_download_wait(device_id)
}

#' Check or wait for an Axivity device's download progress
#'
#' @param device_id Integer device ID, as returned by [axivity_discover()].
#' @return A list with `status` (`"none"`, `"error"`, `"progress"`,
#'   `"complete"`, or `"cancelled"`) and `value` (percentage complete if
#'   `status` is `"progress"`, a diagnostic code if `"error"`).
#' @export
axivity_download_status <- function(device_id) {
  r <- .om_check(axR_omapi_query_download_cpp(device_id))
  list(status = .download_status_labels[r$download_status + 1L], value = r$value)
}

#' @rdname axivity_download_status
#' @export
axivity_download_wait <- function(device_id) {
  r <- .om_check(axR_omapi_wait_download_cpp(device_id))
  list(status = .download_status_labels[r$download_status + 1L], value = r$value)
}

#' Cancel an in-progress download from an Axivity device
#'
#' @param device_id Integer device ID, as returned by [axivity_discover()].
#' @export
axivity_download_cancel <- function(device_id) {
  .om_check(axR_omapi_cancel_download_cpp(device_id))
  invisible(NULL)
}

#' Copy recorded data directly off a mounted Axivity volume
#'
#' A fallback for when [axivity_discover()]/OMAPI device access isn't
#' working, but the device's USB mass-storage volume mounts and is
#' visible in Finder/`diskutil` regardless -- a common split, since the
#' storage side and OMAPI's own IOKit-level device discovery are
#' independent paths (see `NEWS.md` for the discovery issues hit so
#' far). This bypasses OMAPI and `device_id` entirely: it's a plain file
#' copy, nothing more. `axR` doesn't parse `.cwa` contents -- see
#' `mrpheus` or `zeitR` for that.
#'
#' @param device_path Character. Path to the mounted device volume, e.g.
#'   `"/Volumes/CWA17_46171"`. Find this in Finder, or with
#'   `list.files("/Volumes")`.
#' @param dest_dir Character. Destination directory for downloaded
#'   files. Created (recursively) if it doesn't already exist.
#' @param pattern Character. Regex to filter which files are copied,
#'   matched case-insensitively. Default `"\\.cwa$"`.
#' @param overwrite Logical. Overwrite existing files at the
#'   destination. Default `FALSE`.
#'
#' @return Character vector of destination file paths that were
#'   successfully copied.
#'
#' @export
axivity_copy_data <- function(device_path, dest_dir, pattern = "\\.cwa$", overwrite = FALSE) {
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
