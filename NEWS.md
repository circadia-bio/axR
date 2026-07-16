## axR 0.1.1  (2026-07)

### 🐛 Bug fixes

* r-universe's WebAssembly/webR build failed:
  `wasm-ld: error: unable to find library -ludev`. `configure`'s
  Darwin/Linux detection (`uname -s`) can't distinguish this target --
  it reports the *host* OS ("Linux") even when cross-compiling to
  `wasm32-unknown-emscripten` via `emconfigure`, so it picked the Linux
  branch requiring `libudev`, which doesn't exist in a WASM sandbox at
  all (there's no OS device layer to speak of in a browser context, and
  raw USB/serial access isn't available to a WASM module regardless).
  Not a missing library to chase down -- device discovery genuinely
  doesn't apply to this target.
  - `configure` now detects an Emscripten cross-compile by checking the
    `--host` argument it's actually invoked with (confirmed via the
    real build log: `--host=wasm32-unknown-emscripten`) and `$CC`,
    since `uname -s` alone can't tell.
  - New `omapi-devicefinder-wasm.c`: genuine no-op stub implementing
    just the two functions OMAPI's platform-independent code calls
    (`OmDeviceDiscoveryStart()`/`OmDeviceDiscoveryStop()`), so the
    package still compiles for webR/browser use.
    `axivity_read_cwa()`/`axivity_copy_data()` and everything else not
    dependent on a live device still work under this target;
    `axivity_discover()` just always reports zero devices, gracefully,
    rather than failing to build at all.
* r-universe's own separate Windows check (first real signal since our
  own CI's Windows job only confirmed the package *links*, not a full
  `R CMD check`) flagged 8 compiler warnings in
  `omapi-devicefinder-win.cpp` -- all cosmetic, the package installed
  successfully regardless (`Status: 1 WARNING`, not an error).
  - `ConnectServer(...)`'s 5th argument (`lSecurityFlags`, a `LONG`)
    and `PostMessage(...)`'s 3rd/4th arguments (`WPARAM`/`LPARAM`,
    also integer types) were passed `NULL` -- harmless (`NULL` expands
    to 0), but flagged as passing NULL to a non-pointer argument.
    Changed to `0` to match the actual parameter types.
  - Five `!= NULL` checks on `root`/`desiredVolumePath`, both
    fixed-size stack arrays whose address can never be NULL -- always
    true, flagged as such. Dropped, keeping the meaningful
    "is this actually populated" half of each check.
* r-universe's own Windows check also flagged "object files in source
  package" (`src/omapi/*.o`, `RcppExports.o`, `axR-omapi.o`, `axR.so`)
  on a *fresh* CI checkout -- not just a stale local build. Two false
  starts before the real fix: `git rm --cached` found these paths
  weren't actually tracked in git at all (ruling out an accidental
  early commit), and explicitly re-marking `configure`/`cleanup`
  executable via `git update-index --chmod=+x` found the bit was
  already correct. The real fix doesn't depend on figuring out
  exactly why `cleanup` wasn't purging these by packaging time: added
  `\.o$`/`\.so$`/`\.dll$` to `.Rbuildignore`, which `R CMD build`
  applies unconditionally when assembling the tarball, regardless of
  whatever's sitting in the working directory at build time -- more
  robust than relying on a cleanup script's timing relative to the
  build steps.

### 🚀 CI

* New `wasm-build` job in `.github/workflows/R-CMD-check.yaml`, using
  `r-wasm/actions/build-rwasm@v3` (self-contained, no special
  container needed). Catches WASM/webR build failures (like the
  `-ludev` one above) directly in this repo's own CI, rather than only
  discovering them after r-universe attempts its own wasm build.

### 📚 Documentation

* Added a Zenodo DOI (`10.5281/zenodo.21393893`): DOI badge and a
  `📄 Citation` section in `README.md`, plus `CITATION.cff`, matching
  zeitR/mrpheus's pattern.

## axR 0.1.0  (2026-07)

### ✨ New features

* Initial release. Talks to Axivity AX3/AX6 accelerometer devices:
  discovery, status, settings, data download, and reading recorded
  `.cwa`/AX6 binary files -- by wrapping the Open Movement Project's
  OMAPI C library (vendored in `src/omapi`, BSD 2-clause, Newcastle
  University), rather than reimplementing the serial protocol or
  binary file format directly. OMAPI is the same library behind
  Axivity's own OmGui software.
* `axivity_discover()` -- backed by `OmGetDeviceIds()` plus per-device
  status calls, returning `device_id`, `serial`, `port`, `path`,
  `firmware_version`, `hardware_version`, `battery_level`. Every other
  device-facing function takes a `device_id` from this table -- there's
  no `axivity_open()`/`close()` step; the OMAPI session starts when axR
  is loaded (`OmStartup()` in `.onLoad()`) and stops when it's unloaded.
* Status: `axivity_get_battery()`, `axivity_self_test()`,
  `axivity_get_memory_health()`, `axivity_get_accelerometer()`,
  `axivity_get_time()`/`set_time()` (as `POSIXct`), `axivity_set_led()`,
  `axivity_is_locked()`/`set_lock()`/`unlock()`, `axivity_get_ecc()`/
  `set_ecc()`, and `axivity_send_command()` as a raw escape hatch
  (`OmCommand()`).
* Settings: `axivity_get_delays()`/`set_delays()` (`-Inf`/`Inf` as
  R-side sentinels for OMAPI's zero/infinite `OM_DATETIME` values),
  `axivity_get_session_id()`/`set_session_id()`,
  `axivity_get_metadata()`/`set_metadata()`,
  `axivity_get_accel_config()`/`set_accel_config()`, and
  `axivity_reset(level = c("none","delete","quickformat","wipe"))`
  matching OMAPI's `OM_ERASE_LEVEL` enum directly.
* Data download: `axivity_get_data_info()` (size, filename, block
  layout, recorded time range), `axivity_download()` wrapping
  `OmBeginDownloading()` (OMAPI's own background-thread download) with
  `axivity_download_status()`/`_wait()`/`_cancel()` for polling and
  cancellation.
* `axivity_copy_data(device_path, dest_dir, ...)` -- a fallback that
  bypasses OMAPI/`device_id` entirely and copies `.cwa` files straight
  off a mounted volume path. For use while `axivity_discover()` isn't
  finding the device via OMAPI's discovery, but the mass-storage side
  still mounts fine regardless (see Known limitations).
* `axivity_read_cwa(path)` -- parses a `.cwa`/AX6 file directly via
  OMAPI's own binary reader (`omapi-reader.c`, already vendored),
  rather than leaving all parsing to zeitR or building a second,
  differently-sourced parser. A deliberate exception to axR's
  "dumb pipe" scope -- see `?axivity_read_cwa`. Whole block-reading loop
  runs in C++, not R (a multi-day 100Hz recording is millions of
  samples). Returns a tibble (plain data frame if `tibble` isn't
  installed): one row per sample, `timestamp` (`POSIXct`, sub-second
  precision), `x`/`y`/`z` (accelerometer, in g), `gx`/`gy`/`gz` and
  `mx`/`my`/`mz` (gyro/magnetometer, only if present -- e.g. AX6
  GA/GAM mode), `light`/`temperature_c`/`battery_pct`/`sample_rate` at
  block granularity. `device_id`/`session_id`/`metadata` attached as
  attributes. Doesn't require a live device or prior discovery -- works
  on any `.cwa`/AX6 file already on disk, including one still sitting
  on a mounted device volume.
* `axivity_enable_debug_log(file = NULL)` -- re-enables OMAPI's internal
  `OmLog()` diagnostic trace (stderr by default, or a file, since raw
  stderr writes from OMAPI's background discovery pthread don't always
  reach the R console depending on frontend). Debug *level* is separately
  controlled by the `OMDEBUG` environment variable, read once at
  `OmStartup()` time -- i.e. before `library(axR)`, in a fresh session.

### 🐛 Bug fixes -- vendored OMAPI, found via real-device and CI testing

Four separate crashes were found and fixed via live-device testing on
macOS (26.2, real AX3), plus a further round from R-CMD-check actually
compiling the Linux and Windows device finders for the first time
(previously only ever built/tested on macOS):

* **macOS, `DeviceNotification()` (device removal callback):**
  - `CFRelease(deviceData->deviceName)` crashed with
    `*** CFRelease() called with NULL ***` (`EXC_BREAKPOINT`) on
    unplug. Older CoreFoundation treated `CFRelease(NULL)` as a silent
    no-op; recent macOS hardens it into a hard abort -- a decade-old
    latent bug in the vendored code, newly fatal rather than newly
    introduced. Fixed with a NULL guard.
  - `Release()` through `deviceData->deviceInterface` crashed with
    `SIGSEGV` even with `deviceInterface` itself non-NULL -- the
    vtable it pointed to was no longer valid by the time this fires
    (the physical device is already gone). Stopped calling it.
  - A double-free (`free(deviceData)` twice,
    `SIGABRT`/`___BUG_IN_CLIENT_OF_LIBMALLOC_...`) consistent with
    IOKit delivering more than one removal notification for a single
    physical unplug on current macOS. Fixed with an idempotency guard
    (`DeviceData.removed`) -- but the *first* attempt at this guard was
    itself flawed (it stored the flag inside the same memory the
    function also `free()`d, so a duplicate call's guard check was a
    use-after-free that could still let the double-free through).
    Fixed properly by no longer freeing `deviceData` in this handler at
    all -- a bounded, negligible per-removal-event leak in exchange for
    the guard actually being reliable.
  - Also removed a custom `SIGINT` handler that called `exit(0)`
    directly, plus several `fprintf(stderr, ...)` calls duplicating
    adjacent `OmLog()` calls. A vendored library installing a
    process-wide signal handler that terminates the process is
    actively unsafe embedded in a host application (R) with its own
    interrupt handling.
  - `kIOMasterPortDefault` -> `kIOMainPortDefault` (macOS 12+
    deprecation warning; pure rename, no behaviour change).
* **Linux, `omapi-devicefinder-linux.c`:** never compiled until
  R-CMD-check's Linux runner did it for the first time.
  - Three `exit(1)` calls on `udev_new()` failure would each terminate
    the whole R process. Replaced with early returns; callers already
    handle the failure gracefully.
  - This file never used `OmLog()` at all, only raw `printf()`/
    `fprintf(stderr, ...)`, including one *unconditional* debug
    `printf()` inside the background udev monitoring loop that would
    spam stdout on every event. Converted to `OmLog()` (matching the
    macOS finder's convention) so Linux keeps the same diagnostic
    capability via `axivity_enable_debug_log()`.
  - Untested against real Linux hardware -- these are correctness
    fixes for what `R CMD check` flagged, not a claim discovery works
    end-to-end there.
* **Windows, `omapi-devicefinder-win.cpp`:** never compiled until
  R-CMD-check's Windows runner (Rtools45/MinGW-w64) did it for the
  first time. Three rounds of genuine linker/compiler-driven
  iteration, since neither of us has a Windows machine to verify
  against directly:
  - `GUID_DEVINTERFACE_DISK`/`GUID_DEVINTERFACE_VOLUME` undefined at
    link time. First attempt (`#define INITGUID`) made things *worse*
    -- caused `winioctl.h` to be processed twice (once directly, once
    transitively via `windows.h`) with `INITGUID` active both times,
    producing `"redefinition of const GUID ..."` errors for ~20 GUIDs.
    Reverted; fixed instead with `-luuid` in `Makevars.win`, the
    standard MinGW-w64 fix for this exact symptom.
  - `VariantClear`/`SysFreeString` (`-loleaut32`) and
    `CLSID_WbemLocator`/`IID_IWbemLocator` (`-lwbemuuid`) undefined:
    both added to `PKG_LIBS`.
  - `_com_util::ConvertStringToBSTR` (via `_bstr_t`/`bstr_t("...")` in
    two WMI queries) undefined -- confirmed via
    `"cannot find -lcomsuppw: No such file or directory"` that
    Rtools45's MinGW-w64 doesn't ship the MSVC-specific library backing
    it. Both live call sites (most other `bstr_t` matches were inside a
    `/* ... */` dead-code block, never compiled) rewritten to use plain
    `SysAllocString()`/`SysFreeString()` instead.
* Deprecated `ftime()` (glibc: "Use gettimeofday or clock_gettime
  instead") in `omapi-internal.c` and `omapi-devicefinder-linux.c`,
  flagged as a significant install-time warning on the Linux CI
  runner. Switched to `clock_gettime(CLOCK_REALTIME, ...)`.
* `sprintf()` -> `snprintf()` throughout `omapi-status.c`,
  `omapi-settings.c`, and `omapi-devicefinder-mac.c` (bounded, no
  behaviour change). `OmStartup()`'s default log stream changed from
  `stderr` to `NULL` (opt-in only, via `OmSetLogStream()`/
  `axivity_enable_debug_log()`).

All vendored-code divergences from upstream libomapi are flagged
inline with `// axR patch` comments, for anyone re-vendoring later.

### 🚀 CI & pkgdown site

* `.github/workflows/R-CMD-check.yaml`: ubuntu/macOS/windows matrix,
  matching zeitR/mrpheus, plus two axR-specific steps: installing
  `libudev-dev` on Linux (not auto-detected from a prose
  `SystemRequirements` field) and `chmod +x configure cleanup`
  (POSIX only).
* `.github/workflows/pkgdown.yaml`: build/coverage-badge/deploy-to-
  `gh-pages` structure matching zeitR/mrpheus (via
  `JamesIves/github-pages-deploy-action`), same extra steps as above.
* `_pkgdown.yml`: Bootstrap 5 + bslib theming matching zeitR/mrpheus's
  structure, using axR's own hex-sticker palette (navy `#014370`,
  coral `#FC544A`, peach `#FFA75D`, cream `#FFECD4`).
* `configure`/`cleanup` (POSIX shell scripts, need `chmod +x`):
  `src/Makevars` is generated from `src/Makevars.in` at install time
  rather than committed statically, moving the Darwin/Linux
  conditional out of Make syntax (`ifeq`, `$(shell)`, `:=`) into shell
  -- fixes an `R CMD check` "GNU extensions in Makefiles" warning.
  `cleanup` removes generated/compiled artefacts before a fresh check.
* `man/figures/logo.png` (rasterized via `rsvg-convert`) and
  `pkgdown/favicon/` (via `pkgdown::build_favicons()`) added.
* README: R CMD CHECK / coverage / pkgdown-site badges; logo moved
  inline with the H1 (a standalone `<img>` lower in the file rendered
  huge and unconstrained on the pkgdown home page).
* Netlify deployment (watching `gh-pages`, `axr.circadia-lab.uk`) is a
  manual step outside this repo.

### 📚 Documentation

* `vignette("axR")` -- discovery, status/settings, downloading,
  `axivity_copy_data()`, `axivity_read_cwa()`.
* Uses the pre-computed vignette pattern: `vignettes/axR.Rmd.orig` is
  the real source (excluded from the built package); `vignettes/axR.Rmd`
  is generated from it via `knitr::knit()`, run locally, with real
  output baked in -- so r-universe/CRAN never need to execute axR code
  to build it. Only the `axivity_read_cwa()` section has `eval = TRUE`
  so far, since it's the only part verified against real hardware;
  re-run and re-bake as more of the package gets verified.

### 🧪 Tests

* `.om_check()` behaviour (list and scalar status, pass-through vs.
  error); `axivity_discover()` shape check with no device connected;
  `axivity_reset()`/`axivity_set_led()` argument validation
  (`match.arg()` failures) -- none require hardware.

### 👥 Authors

* Mario Leocadio-Miguel added as an author.

### ⚠️ Known limitations

* `axivity_discover()` is not yet finding a real AX3 device on at
  least one tested machine (macOS 26.2), despite `ioreg` confirming
  the device enumerates correctly at the IOKit level with the expected
  VID/PID (`0x04D8`/`0x0057`) and serial. Root cause not yet
  identified -- waiting on input from an Axivity/OMAPI contact.
  `axivity_copy_data()`/`axivity_read_cwa()` work independently of this
  in the meantime, since the device's mass-storage mount isn't affected.
* `axivity_read_cwa()`'s `temperature_c` is unverified and likely wrong
  on at least some hardware revisions -- the vendored conversion
  formula is specific to one temperature sensor chip, with a different
  formula noted for another chip right beside it in the source.
  `timestamp`, `x`/`y`/`z`, and `device_id` have been verified correct
  against a real AX3 recording.
* Windows and Linux device discovery compile clean but are untested
  against real hardware on either platform.
* Windows discovery uses a fixed `COM1`-`COM40` probe range rather than
  true device enumeration.
* Not tested against an AX6, only a real AX3.
* `axivity_get_metadata()`'s padding-trim regex hasn't been checked
  against a real device's returned buffer.
* No `card.png` (pkgdown social-preview card) yet -- only the hex
  sticker logo itself.
