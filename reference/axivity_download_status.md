# Check or wait for an Axivity device's download progress

Check or wait for an Axivity device's download progress

## Usage

``` r
axivity_download_status(device_id)

axivity_download_wait(device_id)
```

## Arguments

- device_id:

  Integer device ID, as returned by
  [`axivity_discover()`](https://axr.circadia-lab.uk/reference/axivity_discover.md).

## Value

A list with `status` (`"none"`, `"error"`, `"progress"`, `"complete"`,
or `"cancelled"`) and `value` (percentage complete if `status` is
`"progress"`, a diagnostic code if `"error"`).
