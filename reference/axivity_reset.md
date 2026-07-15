# Erase an Axivity device's data storage and commit settings

Wraps OMAPI's `OmEraseDataAndCommit()`. Staged settings changes (delays,
session ID, metadata, accelerometer config) only take full effect when
this is called.

## Usage

``` r
axivity_reset(device_id, level = "quickformat")
```

## Arguments

- device_id:

  Integer device ID, as returned by
  [`axivity_discover()`](https://axr.circadia-lab.uk/reference/axivity_discover.md).

- level:

  One of `"none"` (commit metadata only, not recommended – can cause a
  data/metadata mismatch), `"delete"` (remove and recreate the data
  file), `"quickformat"` (recreate the filesystem), or `"wipe"` (clear
  all NAND blocks, cleanest but slowest).
