## axR 0.0.0.9000

* Initial scaffold.
* Package structure drafted: `DESCRIPTION`, `NAMESPACE`, Rcpp/C++ src layout
  (POSIX `termios.h` / Windows `kernel32`, following dynR's Makevars split).

### Serial communication

* `axivity_open()` / `axivity_close()`: open/close a serial connection to an
  Axivity device. POSIX backend via `termios.h` (raw mode, 8N1, no flow
  control, `select()`-based read timeouts); Windows backend via `kernel32`
  (`CreateFile`/`SetCommState`/`SetCommTimeouts`).
* `axivity_send_command()`: send a plain-text command and read the first
  line of the response, following the documented Open Movement serial
  protocol (7-bit ASCII, CR/LF terminated). Multi-line responses (e.g.
  `STREAM`'s preview output) are out of scope for now.
* `axivity_reset()`: sends `FORMAT {Q|W}[C]` to quick-format or fully wipe
  the device, with an optional commit flag. Longer default timeout
  (15s) than other commands, since formatting causes the device's mass
  storage volume to briefly eject and re-appear.
* `axivity_discover()`: probes candidate serial ports
  (`/dev/tty.usbmodem*`, `/dev/cu.usbmodem*`, `/dev/ttyACM*`,
  `/dev/ttyUSB*` on POSIX; `COM1`-`COM40` on Windows) with the `ID`
  command and matches on the device's own reported signature (`CWA` for
  AX3, `AX6` for AX6) rather than a USB VID/PID, so it isn't tied to any
  particular USB descriptor. Windows port range is a placeholder pending
  SetupAPI-based enumeration.

### Data download

* `axivity_download()`: copies files matching a pattern (default
  `.cwa`) from a mounted device volume to a destination directory.
  Plain file copy over the device's USB mass storage interface -- no
  `.cwa` parsing.

### Tests

* `axivity_reset()` command-string construction, covered without hardware
  via `testthat::local_mocked_bindings()`.
* `axivity_download()` covered fully via `withr::local_tempdir()` fixtures
  (matching/non-matching files, missing device path, missing dest dir,
  case-insensitive pattern).
* `axivity_open()`/`axivity_discover()` error-path and shape checks that
  don't require a physical device.

### Known gaps

* Not yet tested against a physical AX3/AX6 device.
* Windows discovery uses a fixed COM port range rather than true
  enumeration.
* `axivity_send_command()` only captures a single response line.
