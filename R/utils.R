# ── Internal utilities ────────────────────────────────────────────────────────
# Shared helper functions used across axR. Mirrors zeitR's R/utils.R message
# helpers so error/warning/inform style stays consistent across the ecosystem.
# Not exported.

# ── Messages ──────────────────────────────────────────────────────────────────

#' @noRd
axr_abort <- function(msg, ..., .envir = parent.frame()) {
  cli::cli_abort(msg, ..., .envir = .envir)
}

#' @noRd
axr_warn <- function(msg, ..., .envir = parent.frame()) {
  cli::cli_warn(msg, ..., .envir = .envir)
}

#' @noRd
axr_inform <- function(msg, ..., .envir = parent.frame()) {
  cli::cli_inform(msg, ..., .envir = .envir)
}

# ── NULL coalescing operator ───────────────────────────────────────────────────

#' @noRd
`%||%` <- function(a, b) if (!is.null(a) && !is.na(a) && nchar(a) > 0) a else b
