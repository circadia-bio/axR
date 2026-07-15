# Get or set an Axivity device's accelerometer configuration

Get or set an Axivity device's accelerometer configuration

## Usage

``` r
axivity_get_accel_config(device_id)

axivity_set_accel_config(device_id, rate, range)
```

## Arguments

- device_id:

  Integer device ID, as returned by
  [`axivity_discover()`](https://axr.circadia-lab.uk/reference/axivity_discover.md).

- rate:

  Sampling rate in Hz (6 = 6.25, 12 = 12.5, 25, 50, 100, 200, 400, 800,
  1600, 3200). Negative = low-power mode.

- range:

  Sampling range in +/- G (2, 4, 8, 16).

## Value

`axivity_get_accel_config()` returns a list with `rate` (Hz) and `range`
(+/- g).
