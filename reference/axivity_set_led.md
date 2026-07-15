# Set an Axivity device's LED colour

Set an Axivity device's LED colour

## Usage

``` r
axivity_set_led(device_id, colour)
```

## Arguments

- device_id:

  Integer device ID, as returned by
  [`axivity_discover()`](https://axr.circadia-lab.uk/reference/axivity_discover.md).

- colour:

  One of `"auto"` (default device-controlled behaviour), `"off"`,
  `"blue"`, `"green"`, `"cyan"`, `"red"`, `"magenta"`, `"yellow"`,
  `"white"`.
