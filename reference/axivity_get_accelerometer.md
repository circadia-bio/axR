# Read an Axivity device's current accelerometer values

Read an Axivity device's current accelerometer values

## Usage

``` r
axivity_get_accelerometer(device_id)
```

## Arguments

- device_id:

  Integer device ID, as returned by
  [`axivity_discover()`](https://axr.circadia-lab.uk/reference/axivity_discover.md).

## Value

A named numeric vector `c(x, y, z)` in units of *g* (raw values are in
1/256 *g*, converted here).
