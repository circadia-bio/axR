# Get or set an Axivity device's real-time clock

Get or set an Axivity device's real-time clock

## Usage

``` r
axivity_get_time(device_id)

axivity_set_time(device_id, time)
```

## Arguments

- device_id:

  Integer device ID, as returned by
  [`axivity_discover()`](https://axr.circadia-lab.uk/reference/axivity_discover.md).

- time:

  A `POSIXct` (or coercible) date/time to set on the device.

## Value

`axivity_get_time()` returns a `POSIXct`.
