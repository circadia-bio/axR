# Getting started with axR

``` r

library(axR)
```

## What axR does

axR talks to Axivity AX3/AX6 accelerometer devices: discovery, status,
settings, data download, and – as of a recent addition – reading
recorded `.cwa`/AX6 binary files directly.

It does this by wrapping the Open Movement Project’s OMAPI C library
(vendored in `src/omapi`), rather than reimplementing the serial
protocol or binary file format from scratch. OMAPI is the same library
behind Axivity’s own OmGui software.

There’s no
`axivity_open()`/[`close()`](https://rdrr.io/r/base/connections.html)
step – the OMAPI session starts automatically when axR is loaded, and
every device-facing function takes a `device_id` you get from
[`axivity_discover()`](https://axr.circadia-lab.uk/reference/axivity_discover.md).

## Discovering devices

``` r

devices <- axivity_discover()
devices
```

This returns one row per connected device, with `device_id`, `serial`,
`port`, `path`, `firmware_version`, `hardware_version`, and
`battery_level`. Everything else in axR that talks to a live device
takes a `device_id` from this table.

``` r

id <- devices$device_id[1]
```

## Checking device status

A handful of read-only queries – safe to run any time:

``` r

axivity_get_battery(id)
axivity_self_test(id)
axivity_get_memory_health(id)
axivity_get_accelerometer(id)   # instantaneous x/y/z, in g
axivity_get_time(id)            # device's RTC, as a POSIXct
```

And a few that change device state, but are harmless and reversible:

``` r

axivity_set_time(id, Sys.time())   # sync the device clock
axivity_set_led(id, "blue")        # visible, easy way to confirm the
                                    # write path is working
```

[`axivity_set_led()`](https://axr.circadia-lab.uk/reference/axivity_set_led.md)
accepts `"auto"`, `"off"`, `"blue"`, `"green"`, `"cyan"`, `"red"`,
`"magenta"`, `"yellow"`, or `"white"`.

## Settings

Delayed activation windows, session IDs, metadata, and accelerometer
configuration can all be read and set:

``` r

axivity_get_delays(id)
axivity_get_session_id(id)
axivity_get_metadata(id)
axivity_get_accel_config(id)

axivity_set_accel_config(id, rate = 100, range = 8)  # 100 Hz, +/-8g
```

[`axivity_get_delays()`](https://axr.circadia-lab.uk/reference/axivity_get_delays.md)/[`axivity_set_delays()`](https://axr.circadia-lab.uk/reference/axivity_get_delays.md)
use `-Inf`/`Inf` as R-side sentinels for OMAPI’s “always”/“never” delay
values.

### Erasing a device

``` r

axivity_reset(id, level = "quickformat")
```

`level` is one of `"none"` (commit metadata only – **not recommended**,
can cause a data/metadata mismatch), `"delete"`, `"quickformat"`
(default), or `"wipe"` (slowest, most thorough). Staged settings changes
(delays, session ID, metadata, accelerometer config) only take full
effect once this is called – see OMAPI’s own documentation for the
detail on why.

This erases the device. There’s no undo.

## Downloading recorded data

``` r

info <- axivity_get_data_info(id)
info  # size, filename, block layout, and the recorded time range

axivity_download(id, "session.cwa")  # blocks until done by default
```

For long downloads, `blocking = FALSE` lets you poll instead of waiting:

``` r

axivity_download(id, "session.cwa", blocking = FALSE)
axivity_download_status(id)   # check progress without blocking
axivity_download_wait(id)     # block until it finishes, whenever you're ready
# axivity_download_cancel(id) # if you change your mind
```

### If discovery isn’t finding your device

OMAPI’s device discovery and the device’s USB mass-storage mount are two
independent things – it’s possible for the storage side to mount and
appear in Finder/Explorer just fine while OMAPI’s own IOKit/SetupAPI
device matching doesn’t find it (this has happened during axR’s own
development – see `NEWS.md`). If that happens, and you can see the
device’s volume directly:

``` r

list.files("/Volumes")  # macOS -- find the device's volume name

axivity_copy_data("/Volumes/AX317_46171", "~/axr_data")
```

This bypasses OMAPI/`device_id` entirely – it’s a plain file copy from
whatever path you give it.

## Reading .cwa files

[`axivity_read_cwa()`](https://axr.circadia-lab.uk/reference/axivity_read_cwa.md)
doesn’t need a live device at all – it works on any `.cwa`/AX6 file
already on disk, whether that’s one you downloaded with
[`axivity_download()`](https://axr.circadia-lab.uk/reference/axivity_download.md)/[`axivity_copy_data()`](https://axr.circadia-lab.uk/reference/axivity_copy_data.md),
or the file sitting directly on the device’s still-mounted volume
(there’s no need to copy it first just to read it):

``` r

data <- axivity_read_cwa("~/axr_test_data/CWA-DATA.CWA")
data
#> # A tibble: 11,621,520 × 8
#>    timestamp                x       y     z light temperature_c battery_pct sample_rate
#>    <dttm>               <dbl>   <dbl> <dbl> <int>         <dbl>       <int>       <int>
#>  1 2026-07-14 12:34:48 -0.281 -0.484  0.688     1         -28.3           0         120
#>  2 2026-07-14 12:34:48 -0.656 -0.109  0.562     1         -28.3           0         120
#>  3 2026-07-14 12:34:48 -0.703 -0.109  0.594     1         -28.3           0         120
#>  4 2026-07-14 12:34:48 -0.703 -0.125  0.609     1         -28.3           0         120
#>  5 2026-07-14 12:34:48 -0.703 -0.125  0.609     1         -28.3           0         120
#>  6 2026-07-14 12:34:48 -0.703 -0.109  0.594     1         -28.3           0         120
#>  7 2026-07-14 12:34:48 -0.703 -0.109  0.578     1         -28.3           0         120
#>  8 2026-07-14 12:34:48 -0.703 -0.0938 0.594     1         -28.3           0         120
#>  9 2026-07-14 12:34:48 -0.703 -0.0938 0.609     1         -28.3           0         120
#> 10 2026-07-14 12:34:48 -0.719 -0.109  0.594     1         -28.3           0         120
#> # ℹ 11,621,510 more rows
```

One row per sample: `timestamp` (`POSIXct`, sub-second precision),
`x`/`y`/`z` (accelerometer, in g), `gx`/`gy`/`gz` and `mx`/`my`/`mz`
(gyroscope/magnetometer, only present if the recording has them –
e.g. AX6 in GA/GAM mode), and `light`/`temperature_c`/`battery_pct`/
`sample_rate` (these last four are read once per data block and repeated
across that block’s samples, not truly per-sample readings).

``` r

attr(data, "device_id")
#> [1] 46171
attr(data, "session_id")
#> [1] 0
attr(data, "metadata")
#> [1] ""
```

`device_id` and `session_id` are handy for a quick sanity check that
you’ve opened the file you think you have. `device_id` above has been
independently cross-checked against `ioreg` and the Axivity config web
tool on the same physical device.

**Known caveat:** `temperature_c` should not currently be trusted. The
vendored conversion formula is specific to one temperature sensor chip,
and there’s a note beside it in the source for an alternate formula on
different hardware – see
[`?axivity_read_cwa`](https://axr.circadia-lab.uk/reference/axivity_read_cwa.md)
and `NEWS.md` for detail. Everything else in the output (timestamps,
x/y/z, device_id) has been verified against a real device.

### Handing off to zeitR

The tibble
[`axivity_read_cwa()`](https://axr.circadia-lab.uk/reference/axivity_read_cwa.md)
returns is meant to be a clean starting point for downstream
wrist-actigraphy analysis in zeitR – one row per sample, standard column
names, `POSIXct` timestamps, accelerometer values already in g rather
than device-raw units.

``` r

data <- axivity_read_cwa("~/axr_data/CWA-DATA.CWA")
# zeitR::some_analysis_function(data)
```

(zeitR’s actual entry point for this may differ – check zeitR’s own
documentation for the current expected input shape.)

## A note on scope

axR was originally scoped as a “dumb pipe”: talk to the device, move
bytes, leave all file parsing to downstream packages.
[`axivity_read_cwa()`](https://axr.circadia-lab.uk/reference/axivity_read_cwa.md)
is a deliberate exception to that – OMAPI already ships a complete
`.cwa` reader, and wrapping it directly avoids building a second,
differently-sourced parser for the same format. axR still doesn’t do any
higher-level actigraphy analysis (sleep detection, non-wear detection,
etc.) on the data it reads – that’s zeitR’s job, downstream of the
tibble this returns.

## Known limitations

See `NEWS.md` for the full, current list, but briefly:

- Device discovery has had real issues on at least one tested machine
  (macOS 26.2) despite the device enumerating correctly at the USB/IOKit
  level – root cause still being investigated.
  [`axivity_copy_data()`](https://axr.circadia-lab.uk/reference/axivity_copy_data.md)
  is the workaround in the meantime.
- Windows device discovery uses a fixed `COM1`-`COM40` probe range
  rather than true enumeration.
- `temperature_c` from
  [`axivity_read_cwa()`](https://axr.circadia-lab.uk/reference/axivity_read_cwa.md)
  is unverified and likely wrong on at least some hardware revisions.
- None of this has been tested against an AX6 (only a real AX3).
