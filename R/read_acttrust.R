#' Read a Condor Instruments ActTrust actigraphy file
#'
#' Parses a Condor ActTrust `.txt` export into a tidy tibble (or data frame,
#' if the `tibble` package isn't installed). The file format consists of a
#' variable-length key-value header block followed by semicolon-delimited
#' epoch rows. The header ends at the line beginning with `DATE/TIME`.
#'
#' This is a device-format parser only -- it returns the file's own epoch
#' columns and does not add any pipeline-specific columns or classes.
#' Downstream packages (e.g. `zeitR`) are expected to wrap this in their own
#' function to reshape the output into their pipeline's shape, the same way
#' `zeitR::read_axivity()` currently wraps [axivity_read_cwa()].
#'
#' @param path `character(1)` or `fs::path`. Path to the ActTrust `.txt` file.
#' @param tz `character(1)`. Time zone string passed to
#'   [lubridate::parse_date_time()]. Defaults to `"UTC"`. Set to the local
#'   recording time zone for correct circadian alignment.
#' @param encoding `character(1)`. File encoding. Defaults to `"latin1"`,
#'   which matches Condor's default export encoding.
#'
#' @return A tibble (or plain data frame, if the `tibble` package isn't
#'   installed) with one row per epoch and the following columns:
#'   \describe{
#'     \item{`datetime`}{`POSIXct` — epoch timestamp.}
#'     \item{`activity`}{`double` — PIM activity count.}
#'     \item{`int_temp`}{`double` — internal (on-body) temperature, degC.}
#'     \item{`ext_temp`}{`double` — external (ambient) temperature, degC.
#'       `NA` if unavailable.}
#'     \item{`ZCMn`}{`double` — normalised zero-crossing mode count.
#'       `NA` if unavailable.}
#'     \item{`light`}{`double` — total light intensity (lux).
#'       `NA` if unavailable.}
#'   }
#'   A `metadata` attribute is attached (a named list with `subject`,
#'   `device_id`, `device_model`, `firmware_version`, `interval_s`,
#'   `source_file`) -- the same attribute pattern used by
#'   [axivity_read_cwa()].
#'
#' @seealso [axivity_read_cwa()] for the Axivity `.cwa` equivalent.
#'
#' @export
#'
#' @importFrom lubridate parse_date_time
#'
#' @examples
#' \dontrun{
#' rec <- read_acttrust("recordings/P001.txt")
#' rec
#' attr(rec, "metadata")
#' }
read_acttrust <- function(path, tz = "UTC", encoding = "latin1") {
  path <- as.character(path)
  if (!file.exists(path)) {
    axr_abort("File not found: {.path {path}}")
  }

  lines <- readLines(path, encoding = encoding, warn = FALSE)

  # ── Parse header ────────────────────────────────────────────────────────────
  # Header lines are "KEY : VALUE"; data starts after the "DATE/TIME;..." line
  header_end <- which(grepl("^DATE/TIME", lines, ignore.case = FALSE))
  if (length(header_end) == 0L) {
    axr_abort(
      "Could not locate the {.code DATE/TIME} column header line in {.path {path}}.
       Is this a valid ActTrust export?"
    )
  }
  header_end <- header_end[1L]

  header_lines <- lines[seq_len(header_end - 1L)]
  kv_pattern   <- "^([A-Z_/ ]+)\\s*:\\s*(.+)$"
  kv_matches   <- regmatches(header_lines,
                             regexpr(kv_pattern, header_lines, perl = TRUE))

  meta_raw <- list()
  for (kv in kv_matches) {
    parts           <- strsplit(kv, "\\s*:\\s*", perl = TRUE)[[1L]]
    key             <- trimws(parts[1L])
    val             <- trimws(paste(parts[-1L], collapse = ":"))
    meta_raw[[key]] <- val
  }

  metadata <- list(
    subject          = meta_raw[["SUBJECT_NAME"]]     %||% NA_character_,
    device_id        = meta_raw[["DEVICE_ID"]]        %||% NA_character_,
    device_model     = meta_raw[["DEVICE_MODEL"]]     %||% NA_character_,
    firmware_version = meta_raw[["FIRMWARE_VERSION"]] %||% NA_character_,
    interval_s       = as.integer(meta_raw[["INTERVAL"]] %||% NA_integer_),
    source_file      = normalizePath(path, mustWork = FALSE)
  )

  # ── Parse data block ────────────────────────────────────────────────────────
  data_lines <- lines[seq(header_end, length(lines))]
  if (length(data_lines) < 2L) {
    axr_abort("No data rows found after the header in {.path {path}}.")
  }

  con <- textConnection(paste(data_lines, collapse = "\n"))
  on.exit(close(con), add = TRUE)

  raw <- utils::read.csv(
    con,
    sep              = ";",
    header           = TRUE,
    check.names      = FALSE,
    stringsAsFactors = FALSE,
    fileEncoding     = ""      # already read as character
  )

  # ── Column mapping ───────────────────────────────────────────────────────────
  # Raw ActTrust name  ->  standard name
  col_map <- c(
    "DATE/TIME"       = "datetime",
    "PIM"             = "activity",
    "TEMPERATURE"     = "int_temp",
    "EXT TEMPERATURE" = "ext_temp",
    "ZCMn"            = "ZCMn",
    "LIGHT"           = "light"
  )

  present    <- intersect(names(col_map), names(raw))
  raw        <- raw[, present, drop = FALSE]
  names(raw) <- col_map[present]

  # ── Required columns check ──────────────────────────────────────────────────
  required <- c("datetime", "activity", "int_temp")
  missing  <- setdiff(required, names(raw))
  if (length(missing) > 0L) {
    axr_abort(
      "Required column(s) not found after parsing {.path {path}}: {.val {missing}}"
    )
  }

  # ── Type coercion ────────────────────────────────────────────────────────────
  raw$datetime <- lubridate::parse_date_time(
    raw$datetime,
    orders = c("dmy HMS", "ymd HMS", "dmy HM", "ymd HM"),
    tz     = tz
  )

  raw$activity <- suppressWarnings(as.double(raw$activity))
  raw$int_temp <- suppressWarnings(as.double(raw$int_temp))

  if (!"ext_temp" %in% names(raw)) raw$ext_temp <- NA_real_
  if (!"ZCMn"     %in% names(raw)) raw$ZCMn     <- NA_real_
  if (!"light"    %in% names(raw)) raw$light    <- NA_real_

  raw$ext_temp <- suppressWarnings(as.double(raw$ext_temp))
  raw$ZCMn     <- suppressWarnings(as.double(raw$ZCMn))
  raw$light    <- suppressWarnings(as.double(raw$light))

  # ── Return ───────────────────────────────────────────────────────────────────
  out <- raw
  if (requireNamespace("tibble", quietly = TRUE)) {
    out <- tibble::as_tibble(out)
  }
  attr(out, "metadata") <- metadata

  out
}
