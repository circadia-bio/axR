test_that(".om_check() passes through non-negative status", {
  expect_equal(.om_check(5L), 5L)
  expect_equal(.om_check(list(status = 0L, value = "x"))$value, "x")
})

test_that(".om_check() errors on negative status", {
  expect_error(.om_check(-1L), "OMAPI error")
  expect_error(.om_check(list(status = -5L)), "OMAPI error")
})

test_that("axivity_discover() returns a well-formed zero-row data frame when nothing is connected", {
  result <- axivity_discover()
  expect_s3_class(result, "data.frame")
  expect_setequal(
    names(result),
    c("device_id", "serial", "port", "path", "firmware_version", "hardware_version", "battery_level")
  )
})

test_that("axivity_reset() validates level before touching a device", {
  expect_error(axivity_reset(999L, level = "bogus"))
})

test_that("axivity_set_led() validates colour before touching a device", {
  expect_error(axivity_set_led(999L, "chartreuse"))
})
