## axR 0.0.0.9000

* Initial scaffold: `DESCRIPTION`, `NAMESPACE`, Rcpp/C++ src layout.

### Architecture change: wraps OMAPI rather than reimplementing the serial protocol

* Retired the hand-rolled `termios.h`/`kernel32` serial implementation
  (moved to `attic/serial.cpp` -- not part of the build).
* Vendored the Open Movement Project's OMAPI C library into `src/omapi`
  (BSD 2-clause, Newcastle University; see `src/omapi/LICENSE.TXT`).
  OMAPI is the same library behind Axivity's own OmGui, with maintained
  platform-specific device discovery (IOKit/DiskArbitration on macOS,
  SetupAPI on Windows, udev on Linux).
* `src/axR-omapi.cpp`: thin Rcpp wrapper -- translates between R types and
  OMAPI's `int deviceId` / out-parameter / negative-error-code convention.
  No device logic reimplemented here.
* `.onLoad()`/`.onUnload()` (`R/zzz.R`) call `OmStartup()`/`OmShutdown()`;
  there's no separate `axivity_open()`/`close()` step.
* `SystemRequirements` in `DESCRIPTION`: Linux needs `libudev-dev` (or
  equivalent) for device discovery. macOS/Windows use OS
  frameworks/APIs with no separate install step.

### Discovery

* `axivity_discover()`: now backed by `OmGetDeviceIds()` plus per-device
  status calls, returning `device_id`, `serial`, `port`, `path`,
  `firmware_version`, `hardware_version`, `battery_level`.

### Status

* `axivity_get_battery()`, `axivity_self_test()`,
  `axivity_get_memory_health()`, `axivity_get_accelerometer()`,
  `axivity_get_time()`/`set_time()` (as `POSIXct`), `axivity_set_led()`,
  `axivity_is_locked()`/`set_lock()`/`unlock()`, `axivity_get_ecc()`/
  `set_ecc()`, and `axivity_send_command()` (now backed by `OmCommand()`
  instead of raw serial).

### Settings

* `axivity_get_delays()`/`set_delays()` (`-Inf`/`Inf` as R-side sentinels
  for OMAPI's zero/infinite `OM_DATETIME` values), `axivity_get_session_id()`/
  `set_session_id()`, `axivity_get_metadata()`/`set_metadata()`,
  `axivity_get_accel_config()`/`set_accel_config()`.
* `axivity_reset()`: **breaking change** from the previous `full`/`commit`
  logical arguments -- now takes `level = c("none","delete","quickformat","wipe")`,
  matching OMAPI's `OM_ERASE_LEVEL` enum directly.

### Data download

* `axivity_download()`: **breaking change** from the previous plain
  `file.copy()` version -- now wraps `OmBeginDownloading()`, OMAPI's own
  background-thread download, with `axivity_download_status()`/`_wait()`/
  `_cancel()` for polling and cancellation. `blocking = TRUE` (default)
  waits for completion; `blocking = FALSE` returns immediately.
* `axivity_get_data_info()`: file size, filename, block layout, and
  recorded time range, from `OmGetDataFileSize()`/`OmGetDataFilename()`/
  `OmGetDataRange()`.

### Design decisions

* No C-level callbacks (`OmSetDownloadCallback()`/`OmSetDeviceCallback()`)
  -- they fire from OMAPI's own background thread, and calling back into R
  from a non-R thread isn't safe. Polling (`axivity_download_status()`,
  `OmWaitForDownload()` via `axivity_download_wait()`) is used instead.

### Tests

* `.om_check()` behaviour (list and scalar status, pass-through vs. error).
* `axivity_discover()` shape check with no device connected.
* `axivity_reset()`/`axivity_set_led()` argument validation
  (`match.arg()` failures), which don't require hardware.
* Prior serial-I/O and file-copy tests moved to `attic/` (they tested the
  now-retired API).

### Known gaps

* Not yet tested against a physical AX3/AX6 device.
* `axivity_get_metadata()`'s padding-trim regex hasn't been checked
  against a real device's returned buffer.

### Vendored code patches

* `src/omapi/omapi-devicefinder-mac.c`: `kIOMasterPortDefault` ->
  `kIOMainPortDefault` (2 occurrences), silencing a macOS 12+ deprecation
  warning from `R CMD check`. Purely a rename -- `kIOMasterPortDefault`
  remains functional, this isn't a behaviour change. Flagged inline with
  `// axR patch` comments; re-apply if this file is ever re-vendored from
  upstream libomapi.
* `sprintf()` -> `snprintf()` throughout `omapi-status.c`,
  `omapi-settings.c`, and `omapi-devicefinder-mac.c` (all into
  already-fixed-size buffers -- adds a bound, doesn't change behaviour).
  Fixes an `R CMD check` "compiled code" warning about calling
  unbounded `[v]sprintf`.
* `omapi-main.c`: `OmStartup()`'s default log stream changed from
  `stderr` to `NULL` (no logging unless the caller opts in via
  `OmSetLogStream()`/`OmSetLogCallback()`). `OmLog()` already guards on
  `om.log != NULL` before writing, so this is safe -- compiled code
  writing directly to stderr instead of through R's console is exactly
  what the check warns about, and at the default debug level nothing
  was being logged either way.
* `omapi-devicefinder-mac.c`: removed a custom `SIGINT` handler
  (`SignalHandler()`) that called `exit(0)` directly, plus its
  registration via `signal()`. A vendored library installing a
  process-wide signal handler that terminates the process is actively
  unsafe when embedded in a host application (R) that has its own
  interrupt handling -- this is a real robustness fix, not just a lint
  fix. Also removed several `fprintf(stderr, ...)` calls that
  duplicated an adjacent `OmLog()` call (which already supports
  configurable log streams/callbacks).
* `omapi-devicefinder-mac.c`, `DeviceNotification()`: guard
  `CFRelease(deviceData->deviceName)` against NULL. This was crashing
  R (`rsession`) on device *removal* with `*** CFRelease() called with
  NULL ***` / `EXC_BREAKPOINT` on current macOS -- older CoreFoundation
  treated `CFRelease(NULL)` as a silent no-op; recent macOS hardens it
  into a hard abort. A decade-old latent bug in the vendored code,
  newly fatal rather than newly introduced. Found via a real device
  test (macOS 26.2, AX3) -- see the crash report's stack trace
  (`DeviceNotification` at `omapi-devicefinder-mac.c:386`) for the
  original diagnosis.
* `omapi-devicefinder-mac.c`, `DeviceNotification()`: also stopped
  calling `Release()` through `deviceData->deviceInterface` on removal
  -- this crashed with `SIGSEGV`/`EXC_BAD_ACCESS` even with
  `deviceInterface` itself non-NULL, i.e. the vtable it pointed to was
  no longer valid by the time this fires (the physical device is
  already gone -- `kIOMessageServiceIsTerminated`). Unlike the
  `CFRelease(NULL)` fix above, this one is inferred from the crash
  rather than confirmed against documented macOS behaviour -- flagged
  as provisional pending further real-device testing.
* `omapi-devicefinder-mac.c`: added an idempotency guard (`DeviceData.removed`)
  to `DeviceNotification()`, after a third crash appeared on device
  removal -- a double-free (`free(deviceData)` twice,
  `___BUG_IN_CLIENT_OF_LIBMALLOC_POINTER_BEING_FREED_WAS_NOT_ALLOCATED`,
  `SIGABRT`), consistent with IOKit delivering more than one
  `kIOMessageServiceIsTerminated` for a single physical unplug on
  current macOS. **First attempt at this guard was itself flawed**: it
  stored the `removed` flag inside `deviceData`, but the same function
  also `free()`d `deviceData` -- so a duplicate call's guard check was
  reading already-freed memory, which is undefined behaviour and could
  (and did) still let the double-free through. Fixed by no longer
  calling `free(deviceData)` in this handler at all: the guard can only
  be reliable if the memory it checks stays valid, so a bounded,
  negligible leak (one small struct per physical removal event, for
  the life of the R session) is accepted in exchange for the guard
  actually working. Four real crashes found and fixed via one
  afternoon of live-device testing (macOS 26.2, AX3).
* Build system: `src/Makevars` is no longer committed as a static file.
  `configure` (a POSIX shell script) now generates it from
  `src/Makevars.in` at install time, picking the right device-finder
  object and libraries for the platform. This moves the
  Darwin-vs-Linux conditional out of Make syntax (`ifeq`, `$(shell)`,
  `:=`) into shell syntax, fixing an `R CMD check` "GNU extensions in
  Makefiles" warning. `configure` must be executable
  (`chmod +x configure`) -- git doesn't reliably preserve this bit
  across all clone/checkout paths, so double-check after cloning.
  `src/Makevars.win` is untouched (it never had the conditional logic).
* `cleanup` (also a POSIX shell script, also needs `chmod +x`): removes
  `configure`-generated `src/Makevars` and any leftover `.o`/`.so`/`.dll`
  build artefacts (including nested ones in `src/omapi/`, which
  `pkgbuild::clean_dll()` doesn't reach). Run this before `R CMD check`
  if you've built locally beforehand -- the standard companion to a
  `configure` script per 'Configure and cleanup' in the R Extensions
  manual.
