test_that("read_acttrust() parses header metadata and epoch data correctly", {
  # Synthetic ActTrust export: 5 header lines, then a DATE/TIME-led CSV
  # block with 2 epochs, 1 minute apart, all optional columns present.
  lines <- c(
    "SUBJECT_NAME : Test Subject",
    "DEVICE_ID : 12345",
    "DEVICE_MODEL : ActTrust2",
    "FIRMWARE_VERSION : 1.0.0",
    "INTERVAL : 60",
    "DATE/TIME;PIM;TEMPERATURE;EXT TEMPERATURE;ZCMn;LIGHT",
    "15/06/2024 08:30:00;10;25.5;20.1;5;100",
    "15/06/2024 08:31:00;20;25.6;20.2;6;110"
  )
  path <- tempfile(fileext = ".txt")
  writeLines(lines, path)
  on.exit(unlink(path), add = TRUE)

  rec <- read_acttrust(path)

  # ── Epoch data ──────────────────────────────────────────────────────────
  expect_s3_class(rec, "data.frame")
  expect_equal(nrow(rec), 2L)
  expect_setequal(
    names(rec),
    c("datetime", "activity", "int_temp", "ext_temp", "ZCMn", "light")
  )

  # datetime column, header row 6: "15/06/2024 08:30:00" -> dmy HMS ->
  # day 15, month 06 (June), year 2024, 08:30:00
  expect_equal(
    as.numeric(rec$datetime),
    as.numeric(as.POSIXct(
      c("2024-06-15 08:30:00", "2024-06-15 08:31:00"),
      tz = "UTC"
    ))
  )

  # PIM column, rows 7-8: 10, 20
  expect_equal(rec$activity, c(10, 20))
  # TEMPERATURE column, rows 7-8: 25.5, 25.6
  expect_equal(rec$int_temp, c(25.5, 25.6))
  # EXT TEMPERATURE column, rows 7-8: 20.1, 20.2
  expect_equal(rec$ext_temp, c(20.1, 20.2))
  # ZCMn column, rows 7-8: 5, 6
  expect_equal(rec$ZCMn, c(5, 6))
  # LIGHT column, rows 7-8: 100, 110
  expect_equal(rec$light, c(100, 110))

  # ── Metadata attribute ───────────────────────────────────────────────────
  meta <- attr(rec, "metadata")
  expect_equal(meta$subject, "Test Subject")
  expect_equal(meta$device_id, "12345")
  expect_equal(meta$device_model, "ActTrust2")
  expect_equal(meta$firmware_version, "1.0.0")
  expect_equal(meta$interval_s, 60L)
  expect_equal(meta$source_file, normalizePath(path, mustWork = FALSE))

  # No pipeline-specific columns or classes -- device-format parser only
  expect_false("state" %in% names(rec))
  expect_false("offwrist" %in% names(rec))
  expect_false("sleep" %in% names(rec))
  expect_false("zeitr_acttrust" %in% class(rec))
})

test_that("read_acttrust() defaults absent optional columns to NA", {
  # Synthetic export missing EXT TEMPERATURE, ZCMn, and LIGHT entirely --
  # only the required columns (DATE/TIME, PIM, TEMPERATURE) are present.
  lines <- c(
    "SUBJECT_NAME : P002",
    "DATE/TIME;PIM;TEMPERATURE",
    "15/06/2024 08:30:00;10;25.5"
  )
  path <- tempfile(fileext = ".txt")
  writeLines(lines, path)
  on.exit(unlink(path), add = TRUE)

  rec <- read_acttrust(path)

  expect_true(is.na(rec$ext_temp))
  expect_true(is.na(rec$ZCMn))
  expect_true(is.na(rec$light))
  # DEVICE_ID key absent from the header entirely
  expect_true(is.na(attr(rec, "metadata")$device_id))
})

test_that("read_acttrust() errors on a missing file", {
  expect_error(
    read_acttrust(tempfile(fileext = ".txt")),
    "File not found"
  )
})

test_that("read_acttrust() errors when no DATE/TIME header line is found", {
  path <- tempfile(fileext = ".txt")
  writeLines(c("SUBJECT_NAME : P003", "not a valid export"), path)
  on.exit(unlink(path), add = TRUE)

  expect_error(read_acttrust(path), "DATE/TIME")
})

test_that("read_acttrust() errors when required columns are missing after parsing", {
  # DATE/TIME header line present, but PIM/TEMPERATURE are absent --
  # required-column check should fire.
  path <- tempfile(fileext = ".txt")
  writeLines(
    c("SUBJECT_NAME : P004", "DATE/TIME;LIGHT", "15/06/2024 08:30:00;100"),
    path
  )
  on.exit(unlink(path), add = TRUE)

  expect_error(read_acttrust(path), "Required column")
})
