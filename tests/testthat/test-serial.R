test_that("axivity_open() errors on a nonexistent port", {
  expect_error(axivity_open("/dev/nonexistent-axR-test-port"))
})

test_that("axivity_discover() returns a well-formed zero-row data frame when nothing responds", {
  # On a machine with no Axivity device connected, every candidate port
  # either doesn't exist or doesn't answer "ID" with a CWA/AX6 signature.
  result <- axivity_discover(timeout_ms = 200)
  expect_s3_class(result, "data.frame")
  expect_setequal(
    names(result),
    c("port", "type", "hardware_version", "firmware_version", "device_id")
  )
})

test_that("axivity_reset() builds the documented FORMAT command variants", {
  # We can't hit real hardware here, but we can check the command string
  # axivity_reset() would send by intercepting axivity_send_command().
  handle <- structure(list(xptr = NULL, port = "test"), class = "axR_connection")

  sent <- NULL
  testthat::local_mocked_bindings(
    axivity_send_command = function(handle, command, timeout_ms = 2000L) {
      sent <<- command
      invisible(command)
    }
  )

  axivity_reset(handle)
  expect_equal(sent, "FORMAT Q")

  axivity_reset(handle, full = TRUE)
  expect_equal(sent, "FORMAT W")

  axivity_reset(handle, commit = TRUE)
  expect_equal(sent, "FORMAT QC")

  axivity_reset(handle, full = TRUE, commit = TRUE)
  expect_equal(sent, "FORMAT WC")
})
