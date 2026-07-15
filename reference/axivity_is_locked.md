# Check or set an Axivity device's anti-tamper lock

Check or set an Axivity device's anti-tamper lock

## Usage

``` r
axivity_is_locked(device_id)

axivity_set_lock(device_id, code)

axivity_unlock(device_id, code)
```

## Arguments

- device_id:

  Integer device ID, as returned by
  [`axivity_discover()`](https://axr.circadia-lab.uk/reference/axivity_discover.md).

- code:

  Integer lock code. `0` = no lock; `0xffff` is reserved.

## Value

`axivity_is_locked()` returns a list with `locked` and `has_lock_code`
(logicals).
