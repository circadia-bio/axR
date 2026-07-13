## axR 0.0.0.9000

* Initial scaffold.
* Package structure drafted: `DESCRIPTION`, `NAMESPACE`, Rcpp/C++ src layout
  (POSIX `termios.h` / Windows `kernel32`, following dynR's Makevars split).
* Planned exports scaffolded with roxygen docs but not yet implemented:
  `axivity_discover()`, `axivity_open()`, `axivity_close()`,
  `axivity_send_command()`, `axivity_reset()`, `axivity_download()`.
* Serial protocol details (baud rate, timeouts, device VID/PID matching,
  command set) are pending design review before implementation begins.
