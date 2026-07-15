# Get information about an Axivity device's recorded data

Get information about an Axivity device's recorded data

## Usage

``` r
axivity_get_data_info(device_id)
```

## Arguments

- device_id:

  Integer device ID, as returned by
  [`axivity_discover()`](https://axr.circadia-lab.uk/reference/axivity_discover.md).

## Value

A list with `size_bytes`, `filename` (path on the device's own
filesystem, not yet downloaded), `block_size`, `offset_blocks`,
`num_blocks`, and `start`/`end` (`POSIXct`, the time range of the
recorded data).
