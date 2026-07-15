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
* `axivity_copy_data(device_path, dest_dir, ...)`: a fallback that
  bypasses OMAPI/`device_id` entirely and copies `.cwa` files straight
  off a mounted volume path -- for use while `axivity_discover()`
  isn't finding the device via OMAPI's IOKit-level discovery, but the
  mass-storage side still mounts fine regardless (as it did during
  testing -- see "Known gaps" below). Same plain-file-copy logic the
  original pre-OMAPI `axivity_download()` had, just under a name that
  doesn't collide with the current OMAPI-backed one.

### Reading .cwa files -- `axivity_read_cwa()`

* **Scope change from "dumb pipe":** axR now wraps OMAPI's own binary
  file reader (`omapi-reader.c`, vendored, already compiled in) rather
  than leaving all `.cwa`/AX6 parsing to zeitR. Chosen deliberately
  over the alternative (a parity-first port of Julia's Python Condor
  pipeline into zeitR) since OMAPI already ships a complete, working
  reader -- wrapping it directly avoids a second, differently-sourced
  parsing implementation. axR still doesn't do any higher-level
  actigraphy analysis on the result (sleep detection, non-wear
  detection, etc.) -- that's still zeitR's job downstream.
* `axivity_read_cwa(path)`: whole block-reading loop runs in C++, not
  R (a multi-day 100Hz recording is millions of samples; looping
  `.Call()`s per-block from R would be a real performance problem).
  Returns a tibble (plain data frame if `tibble` isn't installed) with
  one row per sample: `timestamp` (`POSIXct`, sub-second precision via
  OMAPI's fractional timestamp), `x`/`y`/`z` (accelerometer, in g),
  `gx`/`gy`/`gz` and `mx`/`my`/`mz` (gyro/magnetometer, only present if
  the recording has them -- e.g. AX6 in GA/GAM mode), plus
  `light`/`temperature_c`/`battery_pct`/`sample_rate` replicated at
  block granularity (these are per-block readings, not per-sample).
  `device_id`, `session_id`, and `metadata` attached as attributes.
  Doesn't require [axivity_discover()] to have found anything -- works
  on any `.cwa`/AX6 file already on disk.
* Added `tibble` to `Suggests`.
* **Known issue, unverified/likely wrong:** `temperature_c` came back
  as `-28.3` on a real AX3 (hardware rev 1.7) recording, which isn't a
  plausible reading. The vendored conversion in `omapi-reader.c`
  (`OM_VALUE_TEMPERATURE_MC`) hardcodes a formula for one specific
  temperature sensor chip (MCP9700), with a comment right next to it
  noting an alternate formula for a different chip (MCP9701) --
  suggesting the conversion is hardware/sensor-revision-specific and
  may not match every AX3 build. x/y/z, timestamps, and device_id all
  independently verified correct against the same file; `temperature_c`
  has not been verified and should not be trusted until checked against
  OmGui's own reading for the same recording (or Axivity's hardware
  documentation for which sensor chip this hardware revision uses).

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

### Documentation

* Added a vignette (`vignettes/axR.Rmd`, `vignette("axR")`) walking
  through discovery, status/settings, downloading,
  `axivity_copy_data()`, and `axivity_read_cwa()`. `VignetteBuilder: knitr`
  added to `DESCRIPTION`.
* **Pre-computed vignette pattern:** `vignettes/axR.Rmd.orig` is the
  real source (excluded from the built package via `.Rbuildignore`);
  `vignettes/axR.Rmd` is generated from it via
  `knitr::knit("vignettes/axR.Rmd.orig", "vignettes/axR.Rmd")`, run
  locally, and the *result* of that (with real output baked in) is
  what's committed and shipped. This means r-universe/CRAN builds never
  need to execute any axR code to build the vignette -- it's already
  static by the time it's built there.
  - Only the `axivity_read_cwa()` section currently has `eval = TRUE`
    in the `.orig` source, since that's the only part of axR verified
    working against real hardware right now. Discovery/status/settings/
    download chunks stay `eval = FALSE` (illustrative only) until
    discovery is fixed and those can be genuinely re-run and re-baked.
  - Re-run the `knitr::knit()` step and re-commit `axR.Rmd` whenever the
    verified-working parts of the package change, or discovery starts
    working and more sections can be flipped to `eval = TRUE`.

### Documentation

* Added a vignette (`vignettes/axR.Rmd`, `vignette("axR")`) walking
  through discovery, status/settings, downloading,
  `axivity_copy_data()`, and `axivity_read_cwa()`. `VignetteBuilder: knitr`
  added to `DESCRIPTION`.
* **Pre-computed vignette pattern:** `vignettes/axR.Rmd.orig` is the
  real source (excluded from the built package via `.Rbuildignore`);
  `vignettes/axR.Rmd` is generated from it via
  `knitr::knit("vignettes/axR.Rmd.orig", "vignettes/axR.Rmd")`, run
  locally, and the *result* of that (with real output baked in) is
  what's committed and shipped. This means r-universe/CRAN builds never
  need to execute any axR code to build the vignette -- it's already
  static by the time it's built there.
  - Only the `axivity_read_cwa()` section currently has `eval = TRUE`
    in the `.orig` source, since that's the only part of axR verified
    working against real hardware right now. Discovery/status/settings/
    download chunks stay `eval = FALSE` (illustrative only) until
    discovery is fixed and those can be genuinely re-run and re-baked.
  - Re-run the `knitr::knit()` step and re-commit `axR.Rmd` whenever the
    verified-working parts of the package change, or discovery starts
    working and more sections can be flipped to `eval = TRUE`.

### pkgdown site & CI

* `_pkgdown.yml`: same structure as zeitR/mrpheus (Bootstrap 5 + bslib
  theming, OpenGraph meta, navbar/footer layout), using axR's own hex
  sticker palette (navy `#014370`, coral `#FC544A`, peach `#FFA75D`,
  cream `#FFECD4`). Reference index grouped by discovery/status/
  settings/download/reading/diagnostics.
* `.github/workflows/R-CMD-check.yaml`: same ubuntu/macOS/windows
  matrix as zeitR/mrpheus, plus two axR-specific steps the reference
  workflow doesn't need: installing `libudev-dev` on the Linux runner
  (not something `setup-r-dependencies` auto-detects from a prose
  `SystemRequirements` field), and `chmod +x configure cleanup` before
  checking (POSIX only -- Windows uses the static `Makevars.win`).
* `.github/workflows/pkgdown.yaml`: same build-site / coverage-badge /
  deploy-to-`gh-pages` structure as zeitR/mrpheus (via
  `JamesIves/github-pages-deploy-action`), with the same `libudev-dev`/
  `chmod +x` steps added for the same reason as the check workflow.
  **Deviates from the reference workflow in one place:** only copies
  `logo.png` to `docs/`, not `card.png` -- axR doesn't have a `card.png`
  (the wider social-preview composite, distinct from the hex logo
  itself) yet. Add that `cp` line back once one exists.
* `man/figures/logo.png` (1080x1241, rasterized from `logo.svg` via
  `rsvg-convert`) and `pkgdown/favicon/` (via
  `pkgdown::build_favicons()`, hitting realfavicongenerator.net's API)
  added -- needed by the pkgdown workflow's OpenGraph image copy and
  favicon `<link>` tags respectively; didn't exist before this.
* `DESCRIPTION`: added `covr`/`pkgdown` to `Suggests`; `URL` now lists
  the pkgdown site alongside the GitHub repo, matching zeitR/mrpheus's
  convention.
* `README.md`: added R CMD CHECK, coverage, and pkgdown-site badges,
  matching zeitR/mrpheus.
* Netlify deployment (watching `gh-pages`, domain `axr.circadia-lab.uk`)
  is a manual step outside this repo -- not something a commit here can
  configure.

### Known gaps

* `axivity_discover()` is not yet finding a real AX3 device (macOS
  26.2), despite `ioreg` confirming the device enumerates correctly at
  the IOKit level with the expected VID/PID (`0x04D8`/`0x0057`) and
  serial (`CWA17_46171`). Root cause not yet identified -- waiting on
  input from an Axivity/OMAPI contact. The device's USB mass-storage
  volume mounts fine independent of this, which is what
  `axivity_copy_data()` (above) works around in the meantime.
* `axivity_get_metadata()`'s padding-trim regex hasn't been checked
  against a real device's returned buffer.

### Authors

* Added Mario Leocadio-Miguel as an author (`DESCRIPTION`, `_pkgdown.yml`,
  `README.md`, `LICENSE`, `LICENSE.md`).

### Vendored code patches (Linux)

* `omapi-devicefinder-linux.c` had never been compiled until the
  R-CMD-check GitHub Actions Linux runner did it for the first time --
  everything up to this point was only ever tested on macOS. Same
  class of issues as the Mac finder, none previously caught:
  - Three `exit(1)` calls on `udev_new()` failure (`GetSerialDevice()`,
    `InitDeviceFinder()`, and the background `OmDeviceDiscoveryThread()`)
    would each terminate the whole R process. Replaced with early
    returns (`return;` / `return NULL;` matching each function's
    signature) -- the callers already handle the failure gracefully
    (e.g. checking `strlen(serial_device) > 0`).
  - This file never used `OmLog()` at all, only raw `printf()`/
    `fprintf(stderr, ...)`, including one *unconditional* debug
    `printf("DEVICE-ACTION: ...")` inside the background monitoring
    loop that would have spammed stdout on every udev event. All
    converted to `OmLog()` calls (matching the Mac finder's
    convention) rather than just deleted, so Linux keeps the same
    diagnostic capability via `axivity_enable_debug_log()`.
  - Untested against real hardware on Linux -- these are correctness
    fixes for what `R CMD check` flagged, not a claim that Linux
    device discovery has been verified working end-to-end.
  - `omapi-internal.c`'s `OmMillisecondsEpoch()` and this file's own
    `timestamp()` both used the deprecated `ftime()` (glibc: "Use
    gettimeofday or clock_gettime instead"), flagged as a "significant
    warning" during install on the Linux CI runner (which fails the
    whole check, since it treats any `WARNING` as a failure). Both
    switched to `clock_gettime(CLOCK_REALTIME, ...)`, same millisecond
    value, no extra linking needed on any glibc from the last decade-plus.

### Vendored code patches (Windows) -- unverified, iterating via CI

* `omapi-devicefinder-win.cpp` failed to *link* on the R-CMD-check
  GitHub Actions Windows runner (Rtools45/MinGW-w64) -- first time this
  file had ever actually been built; unlike the macOS/Linux fixes
  above, neither of us has a Windows machine to verify against, so this
  is a best-effort fix pending the next CI run, not a confirmed one.
  - `GUID_DEVINTERFACE_DISK`/`GUID_DEVINTERFACE_VOLUME` undefined at
    link time: fixed by defining `INITGUID` before `<windows.h>` and
    everything that pulls it in, so the GUID data compiles in locally
    instead of needing an import library -- a standard, compiler-agnostic
    convention (not MSVC-specific), low risk.
  - `VariantClear`/`SysFreeString` (`oleaut32`) and
    `CLSID_WbemLocator`/`IID_IWbemLocator` (`wbemuuid`, needed for this
    file's WMI serial-port queries) undefined: added both libs to
    `Makevars.win`'s `PKG_LIBS`. Confident these exist under any
    MinGW-w64 Windows SDK port.
  - `_com_util::ConvertStringToBSTR` (used throughout via `_bstr_t`/
    `bstr_t("...")` in the file's WMI queries) undefined: added
    `-lcomsuppw` to `PKG_LIBS` as a first attempt. **Genuinely
    uncertain** this resolves it -- `comsuppw` is historically an
    MSVC-specific library backing `_bstr_t`, and whether Rtools45's
    MinGW-w64 ships an equivalent isn't something either of us could
    verify. If the next CI run still fails specifically on this symbol,
    the real fix is rewriting the WMI query construction to avoid
    `_bstr_t` entirely (e.g. via plain `SysAllocString()`), not another
    library name to try.

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
