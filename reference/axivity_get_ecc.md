# Get or set an Axivity device's error-correcting code (ECC) flag

Get or set an Axivity device's error-correcting code (ECC) flag

## Usage

``` r
axivity_get_ecc(device_id)

axivity_set_ecc(device_id, enabled)
```

## Arguments

- device_id:

  Integer device ID, as returned by
  [`axivity_discover()`](https://axr.circadia-lab.uk/reference/axivity_discover.md).

- enabled:

  Logical. Enable or disable ECC.

## Value

`axivity_get_ecc()` returns a logical.
