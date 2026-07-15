# Query an Axivity device's battery level and health

Query an Axivity device's battery level and health

## Usage

``` r
axivity_get_battery(device_id)
```

## Arguments

- device_id:

  Integer device ID, as returned by
  [`axivity_discover()`](https://axr.circadia-lab.uk/reference/axivity_discover.md).

## Value

A list with `level_pct` (0-99% = charging, 100% = full) and
`recharge_cycles` (lower is better).
