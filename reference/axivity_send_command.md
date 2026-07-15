# Send a raw command to an Axivity device

An escape hatch wrapping OMAPI's `OmCommand()`, for anything not covered
by axR's typed functions. Not generally recommended – OMAPI's own docs
note that incorrect use could lead to unspecified behaviour.

## Usage

``` r
axivity_send_command(device_id, command, expected = "", timeout_ms = 2000L)
```

## Arguments

- device_id:

  Integer device ID, as returned by
  [`axivity_discover()`](https://axr.circadia-lab.uk/reference/axivity_discover.md).

- command:

  Character. The command string to send.

- expected:

  Character. The expected response prefix, or `""` if not specified.

- timeout_ms:

  Integer. Timeout in milliseconds. Default `2000`.

## Value

Character. The device's raw response.
