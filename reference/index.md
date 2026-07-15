# Package index

## Discovery

Find connected Axivity devices.

- [`axivity_discover()`](https://axr.circadia-lab.uk/reference/axivity_discover.md)
  : Discover connected Axivity devices

## Status

Battery, self-test, memory health, accelerometer, RTC, LED, lock, ECC.

- [`axivity_get_battery()`](https://axr.circadia-lab.uk/reference/axivity_get_battery.md)
  : Query an Axivity device's battery level and health
- [`axivity_self_test()`](https://axr.circadia-lab.uk/reference/axivity_self_test.md)
  : Run an Axivity device's built-in self-test
- [`axivity_get_memory_health()`](https://axr.circadia-lab.uk/reference/axivity_get_memory_health.md)
  : Query an Axivity device's NAND flash memory health
- [`axivity_get_accelerometer()`](https://axr.circadia-lab.uk/reference/axivity_get_accelerometer.md)
  : Read an Axivity device's current accelerometer values
- [`axivity_get_time()`](https://axr.circadia-lab.uk/reference/axivity_get_time.md)
  [`axivity_set_time()`](https://axr.circadia-lab.uk/reference/axivity_get_time.md)
  : Get or set an Axivity device's real-time clock
- [`axivity_set_led()`](https://axr.circadia-lab.uk/reference/axivity_set_led.md)
  : Set an Axivity device's LED colour
- [`axivity_is_locked()`](https://axr.circadia-lab.uk/reference/axivity_is_locked.md)
  [`axivity_set_lock()`](https://axr.circadia-lab.uk/reference/axivity_is_locked.md)
  [`axivity_unlock()`](https://axr.circadia-lab.uk/reference/axivity_is_locked.md)
  : Check or set an Axivity device's anti-tamper lock
- [`axivity_get_ecc()`](https://axr.circadia-lab.uk/reference/axivity_get_ecc.md)
  [`axivity_set_ecc()`](https://axr.circadia-lab.uk/reference/axivity_get_ecc.md)
  : Get or set an Axivity device's error-correcting code (ECC) flag
- [`axivity_send_command()`](https://axr.circadia-lab.uk/reference/axivity_send_command.md)
  : Send a raw command to an Axivity device

## Settings

Delayed activation, session ID, metadata, accelerometer config, erase.

- [`axivity_get_delays()`](https://axr.circadia-lab.uk/reference/axivity_get_delays.md)
  [`axivity_set_delays()`](https://axr.circadia-lab.uk/reference/axivity_get_delays.md)
  : Get or set an Axivity device's delayed activation window
- [`axivity_get_session_id()`](https://axr.circadia-lab.uk/reference/axivity_get_session_id.md)
  [`axivity_set_session_id()`](https://axr.circadia-lab.uk/reference/axivity_get_session_id.md)
  : Get or set an Axivity device's session identifier
- [`axivity_get_metadata()`](https://axr.circadia-lab.uk/reference/axivity_get_metadata.md)
  [`axivity_set_metadata()`](https://axr.circadia-lab.uk/reference/axivity_get_metadata.md)
  : Get or set an Axivity device's metadata scratch buffer
- [`axivity_get_accel_config()`](https://axr.circadia-lab.uk/reference/axivity_get_accel_config.md)
  [`axivity_set_accel_config()`](https://axr.circadia-lab.uk/reference/axivity_get_accel_config.md)
  : Get or set an Axivity device's accelerometer configuration
- [`axivity_reset()`](https://axr.circadia-lab.uk/reference/axivity_reset.md)
  : Erase an Axivity device's data storage and commit settings

## Data download

Retrieve recorded data from a connected device, or a fallback for when
device discovery isn’t finding it.

- [`axivity_get_data_info()`](https://axr.circadia-lab.uk/reference/axivity_get_data_info.md)
  : Get information about an Axivity device's recorded data
- [`axivity_download()`](https://axr.circadia-lab.uk/reference/axivity_download.md)
  : Download recorded data off an Axivity device
- [`axivity_download_status()`](https://axr.circadia-lab.uk/reference/axivity_download_status.md)
  [`axivity_download_wait()`](https://axr.circadia-lab.uk/reference/axivity_download_status.md)
  : Check or wait for an Axivity device's download progress
- [`axivity_download_cancel()`](https://axr.circadia-lab.uk/reference/axivity_download_cancel.md)
  : Cancel an in-progress download from an Axivity device
- [`axivity_copy_data()`](https://axr.circadia-lab.uk/reference/axivity_copy_data.md)
  : Copy recorded data directly off a mounted Axivity volume

## Reading .cwa files

Parse recorded .cwa/AX6 binary files directly, no device required.

- [`axivity_read_cwa()`](https://axr.circadia-lab.uk/reference/axivity_read_cwa.md)
  : Read a .cwa/AX6 binary file into a tibble

## Diagnostics

Tools for debugging device discovery/communication issues.

- [`axivity_enable_debug_log()`](https://axr.circadia-lab.uk/reference/axivity_enable_debug_log.md)
  : Enable OMAPI's internal debug log

## Package

Package-level documentation.

- [`axR`](https://axr.circadia-lab.uk/reference/axR-package.md)
  [`axR-package`](https://axr.circadia-lab.uk/reference/axR-package.md)
  : axR: Device Communication and .cwa File Reading for Axivity Devices
