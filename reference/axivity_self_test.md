# Run an Axivity device's built-in self-test

Run an Axivity device's built-in self-test

## Usage

``` r
axivity_self_test(device_id)
```

## Arguments

- device_id:

  Integer device ID, as returned by
  [`axivity_discover()`](https://axr.circadia-lab.uk/reference/axivity_discover.md).

## Value

A list with `passed` (logical) and `diagnostic_code` (an opaque,
firmware-specific code; `0` means passed).
