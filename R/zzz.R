.axR_state <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
  .axR_state$startup_status <- axR_omapi_startup_cpp()
}

.onAttach <- function(libname, pkgname) {
  status <- .axR_state$startup_status
  if (!is.null(status) && status < 0) {
    packageStartupMessage(sprintf(
      "axR: OMAPI initialisation failed (%s). Device functions will not work until this is resolved.",
      as.character(axR_omapi_error_string_cpp(status))
    ))
  }
}

.onUnload <- function(libpath) {
  axR_omapi_shutdown_cpp()
}

# Shared error-check helper for both plain-int and list-with-$status
# returns from the axR_omapi_*_cpp() wrappers. OMAPI's convention is
# negative = API error, non-negative = success (some calls overload the
# non-negative return with a meaningful value, e.g. battery percentage --
# callers should read that value from the object returned here, not from
# this check).
.om_check <- function(x) {
  status <- if (is.list(x)) x$status else x
  if (status < 0) {
    stop(sprintf("OMAPI error (%d): %s", status, as.character(axR_omapi_error_string_cpp(status))),
         call. = FALSE)
  }
  x
}
