# Discover connected Axivity devices

Wraps OMAPI's `OmGetDeviceIds()` plus a handful of per-device status
calls into a single data frame. Unlike serial-port probing, this uses
OMAPI's own device discovery – including its platform-specific finder
(IOKit/DiskArbitration on macOS, SetupAPI on Windows, udev on Linux) –
so it should behave the same way OmGui does on the same machine.

## Usage

``` r
axivity_discover()
```

## Value

A data frame with one row per connected device: `device_id`, `serial`,
`port`, `path`, `firmware_version`, `hardware_version`, `battery_level`.
Zero rows if no devices are connected.
