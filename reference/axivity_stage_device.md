# Stage an Axivity device for deployment

Configures a connected Axivity device end-to-end for a participant
deployment: accelerometer settings, deployment window (delays), session
ID, and metadata, then commits everything with a reset so the staged
settings take full effect.

## Usage

``` r
axivity_stage_device(
  device_id,
  start,
  stop = Inf,
  duration = NULL,
  session_id,
  metadata = "",
  rate = 100,
  range = 8,
  reset_level = "quickformat"
)
```

## Arguments

- device_id:

  Character. Device identifier from
  [`axivity_discover()`](https://axr.circadia-lab.uk/reference/axivity_discover.md).

- start:

  POSIXct. Deployment start time. Use `-Inf` for "always".

- stop:

  POSIXct. Deployment stop time. Use `Inf` for "never". Ignored if
  `duration` is supplied.

- duration:

  Optional. A `difftime` (or numeric, in seconds) giving how long after
  `start` the deployment should run. Overrides `stop`.

- session_id:

  Integer. Session identifier for this deployment.

- metadata:

  Character. Free-text metadata (e.g. participant ID, study label)
  written to the device.

- rate:

  Numeric. Accelerometer sampling rate in Hz. Default 100.

- range:

  Numeric. Accelerometer range in g. Default 8.

- reset_level:

  Character. Reset level for
  [`axivity_reset()`](https://axr.circadia-lab.uk/reference/axivity_reset.md)
  once settings are staged. One of `"delete"`, `"quickformat"`
  (default), or `"wipe"`. `"none"` is deliberately not permitted here.

## Value

Invisibly, a list of the settings that were written.
