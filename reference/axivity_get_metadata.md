# Get or set an Axivity device's metadata scratch buffer

Get or set an Axivity device's metadata scratch buffer

## Usage

``` r
axivity_get_metadata(device_id)

axivity_set_metadata(device_id, metadata)
```

## Arguments

- device_id:

  Integer device ID, as returned by
  [`axivity_discover()`](https://axr.circadia-lab.uk/reference/axivity_discover.md).

- metadata:

  Character. Metadata to store (up to 448 bytes; longer values are
  truncated by the device). URL-encode first if it needs to preserve
  non-ASCII characters.

## Value

`axivity_get_metadata()` returns a character string, trimmed of trailing
padding.
