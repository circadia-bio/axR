# Get or set an Axivity device's delayed activation window

Get or set an Axivity device's delayed activation window

## Usage

``` r
axivity_get_delays(device_id)

axivity_set_delays(device_id, start, stop)
```

## Arguments

- device_id:

  Integer device ID, as returned by
  [`axivity_discover()`](https://axr.circadia-lab.uk/reference/axivity_discover.md).

- start, stop:

  Each either a `POSIXct` (or coercible), `-Inf` (always record from now
  / OMAPI's zero sentinel), or `Inf` (never record / OMAPI's infinite
  sentinel).

## Value

`axivity_get_delays()` returns a list with `start` and `stop`, each
either a `POSIXct`, `-Inf` (OMAPI's "always"/zero sentinel), or `Inf`
(OMAPI's "never"/infinite sentinel).
