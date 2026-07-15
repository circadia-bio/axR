# Read a .cwa/AX6 binary file into a tibble

Uses OMAPI's own binary file reader (`omapi-reader.c`, vendored from
libomapi) to parse a `.cwa`/AX6 recording directly, rather than
reimplementing the binary format from scratch. Returns one row per
sample – ready to hand to `zeitR`, or any other downstream actigraphy
analysis.

## Usage

``` r
axivity_read_cwa(path)
```

## Arguments

- path:

  Character. Path to a `.cwa`/AX6 file.

## Value

A tibble (or plain data frame, if the `tibble` package isn't installed)
with one row per sample:

- timestamp:

  `POSIXct`, UTC, with sub-second precision

- x, y, z:

  Accelerometer readings, in g

- gx, gy, gz:

  Gyroscope readings, raw units (only present if the recording has a
  gyroscope, e.g. AX6 in GA/GAM mode)

- mx, my, mz:

  Magnetometer readings, raw units (only present if the recording has a
  magnetometer, e.g. AX6 in GAM mode)

- light:

  Raw light sensor reading

- temperature_c:

  Temperature in degrees Celsius. **Unverified, possibly wrong** –
  OMAPI's conversion (`OM_VALUE_TEMPERATURE_MC`) hardcodes a formula for
  one specific temperature sensor chip (MCP9700); a comment beside it in
  the vendored source notes an alternate formula for a different chip
  (MCP9701), suggesting this may be hardware/revision-specific.
  Cross-check against OmGui's own reading for the same file before
  relying on this.

- battery_pct:

  Battery percentage, at the time of this block

- sample_rate:

  Sampling rate in Hz, at the time of this block

with `device_id`, `session_id`, and `metadata` attached as attributes.
`timestamp`, `x`/`y`/`z`, and `device_id` have been verified correct
against a real AX3 file (cross-checked device_id against `ioreg` and the
Axivity config web tool); `temperature_c` has not.

## Details

Unlike the rest of axR, this function doesn't talk to a live device at
all – it works on a file already on disk (e.g. one retrieved with
[`axivity_copy_data()`](https://axr.circadia-lab.uk/reference/axivity_copy_data.md)
or
[`axivity_download()`](https://axr.circadia-lab.uk/reference/axivity_download.md)),
and doesn't require
[`axivity_discover()`](https://axr.circadia-lab.uk/reference/axivity_discover.md)
to have found anything.
