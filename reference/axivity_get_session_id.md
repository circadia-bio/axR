# Get or set an Axivity device's session identifier

Get or set an Axivity device's session identifier

## Usage

``` r
axivity_get_session_id(device_id)

axivity_set_session_id(device_id, session_id)
```

## Arguments

- device_id:

  Integer device ID, as returned by
  [`axivity_discover()`](https://axr.circadia-lab.uk/reference/axivity_discover.md).

- session_id:

  A value to set as the session ID.

## Value

`axivity_get_session_id()` returns a numeric (session IDs can exceed R's
32-bit integer range).
