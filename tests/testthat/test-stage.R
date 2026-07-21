test_that("axivity_stage_device() rejects reset_level = 'none' before touching a device", {
  expect_error(
    axivity_stage_device(999L, start = Sys.time(), session_id = 1, reset_level = "none"),
    "not supported"
  )
})
