# Read a Condor Instruments ActTrust actigraphy file

Parses a Condor ActTrust `.txt` export into a tidy tibble (or data
frame, if the `tibble` package isn't installed). The file format
consists of a variable-length key-value header block followed by
semicolon-delimited epoch rows. The header ends at the line beginning
with `DATE/TIME`.

## Usage

``` r
read_acttrust(path, tz = "UTC", encoding = "latin1")
```

## Arguments

- path:

  `character(1)` or
  [`fs::path`](https://fs.r-lib.org/reference/path.html). Path to the
  ActTrust `.txt` file.

- tz:

  `character(1)`. Time zone string passed to
  [`lubridate::parse_date_time()`](https://lubridate.tidyverse.org/reference/parse_date_time.html).
  Defaults to `"UTC"`. Set to the local recording time zone for correct
  circadian alignment.

- encoding:

  `character(1)`. File encoding. Defaults to `"latin1"`, which matches
  Condor's default export encoding.

## Value

A tibble (or plain data frame, if the `tibble` package isn't installed)
with one row per epoch and the following columns:

- `datetime`:

  `POSIXct` — epoch timestamp.

- `activity`:

  `double` — PIM activity count.

- `int_temp`:

  `double` — internal (on-body) temperature, degC.

- `ext_temp`:

  `double` — external (ambient) temperature, degC. `NA` if unavailable.

- `ZCMn`:

  `double` — normalised zero-crossing mode count. `NA` if unavailable.

- `light`:

  `double` — total light intensity (lux). `NA` if unavailable.

A `metadata` attribute is attached (a named list with `subject`,
`device_id`, `device_model`, `firmware_version`, `interval_s`,
`source_file`) – the same attribute pattern used by
[`axivity_read_cwa()`](https://axr.circadia-lab.uk/reference/axivity_read_cwa.md).

## Details

This is a device-format parser only – it returns the file's own epoch
columns and does not add any pipeline-specific columns or classes.
Downstream packages (e.g. `zeitR`) are expected to wrap this in their
own function to reshape the output into their pipeline's shape, the same
way `zeitR::read_axivity()` currently wraps
[`axivity_read_cwa()`](https://axr.circadia-lab.uk/reference/axivity_read_cwa.md).

## See also

[`axivity_read_cwa()`](https://axr.circadia-lab.uk/reference/axivity_read_cwa.md)
for the Axivity `.cwa` equivalent.

## Examples

``` r
if (FALSE) { # \dontrun{
rec <- read_acttrust("recordings/P001.txt")
rec
attr(rec, "metadata")
} # }
```
