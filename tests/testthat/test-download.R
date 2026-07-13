test_that("axivity_download() copies matching files and skips others", {
  device_dir <- withr::local_tempdir()
  dest_dir   <- withr::local_tempdir()

  writeLines("dummy", file.path(device_dir, "CWA-DATA.cwa"))
  writeLines("dummy", file.path(device_dir, "readme.txt"))

  result <- axivity_download(device_dir, dest_dir)

  expect_length(result, 1)
  expect_true(file.exists(file.path(dest_dir, "CWA-DATA.cwa")))
  expect_false(file.exists(file.path(dest_dir, "readme.txt")))
})

test_that("axivity_download() is case-insensitive on the pattern", {
  device_dir <- withr::local_tempdir()
  dest_dir   <- withr::local_tempdir()
  writeLines("dummy", file.path(device_dir, "CWA-DATA.CWA"))

  result <- axivity_download(device_dir, dest_dir)
  expect_length(result, 1)
})

test_that("axivity_download() creates dest_dir if missing", {
  device_dir <- withr::local_tempdir()
  dest_dir   <- file.path(withr::local_tempdir(), "nested", "dest")
  writeLines("dummy", file.path(device_dir, "CWA-DATA.cwa"))

  axivity_download(device_dir, dest_dir)
  expect_true(dir.exists(dest_dir))
})

test_that("axivity_download() errors on a missing device path", {
  expect_error(axivity_download(tempfile(), withr::local_tempdir()))
})

test_that("axivity_download() warns and returns character(0) when nothing matches", {
  device_dir <- withr::local_tempdir()
  dest_dir   <- withr::local_tempdir()
  writeLines("dummy", file.path(device_dir, "readme.txt"))

  expect_warning(result <- axivity_download(device_dir, dest_dir))
  expect_length(result, 0)
})
