# Query an Axivity device's NAND flash memory health

Query an Axivity device's NAND flash memory health

## Usage

``` r
axivity_get_memory_health(device_id)
```

## Arguments

- device_id:

  Integer device ID, as returned by
  [`axivity_discover()`](https://axr.circadia-lab.uk/reference/axivity_discover.md).

## Value

A list with `spare_blocks` (higher is better, `0` = unusable) and
`status` (`"ok"`, `"warning"`, or `"error"`, using OMAPI's documented
thresholds).
