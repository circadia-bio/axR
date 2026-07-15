# ⛏️ axR

**Device discovery, status, settings, and data download for Axivity AX3/AX6 accelerometer devices.**
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow)](./LICENSE)
[![R](https://img.shields.io/badge/R-%3E%3D4.1.0-276DC3)](https://www.r-project.org/)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange)](https://lifecycle.r-lib.org/articles/stages.html)
[![R CMD CHECK](https://github.com/circadia-bio/axR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/circadia-bio/axR/actions/workflows/R-CMD-check.yaml)
[![Coverage](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/circadia-bio/axR/gh-pages/badges/coverage.json)](https://github.com/circadia-bio/axR/actions/workflows/pkgdown.yaml)
[![pkgdown](https://img.shields.io/badge/docs-axr.circadia--lab.uk-FC544A)](https://axr.circadia-lab.uk)

---

<img src="man/figures/logo.svg" align="right" height="160" alt="axR logo" />

## 📖 What is axR?

`axR` talks to Axivity AX3/AX6 accelerometers over USB: discovering connected
devices, querying and setting status/configuration, and downloading recorded
`.cwa` files.

Rather than reimplementing the Axivity serial protocol directly, axR wraps
the Open Movement Project's
[OMAPI](https://github.com/openmovementproject/libomapi) C library
(vendored in `src/omapi`, BSD 2-clause, Newcastle University — see
[`src/omapi/LICENSE.TXT`](src/omapi/LICENSE.TXT)). OMAPI is the same library
behind Axivity's own OmGui software, and includes maintained,
platform-specific device discovery (IOKit/DiskArbitration on macOS, SetupAPI
on Windows, udev on Linux) rather than a hand-rolled equivalent.

`axR` is deliberately a "dumb pipe" — it doesn't know anything about `.cwa`
file structure. Parsing recorded data is left to downstream packages such as
[mrpheus](https://github.com/circadia-bio/mrpheus) or
[zeitR](https://github.com/circadia-bio/zeitR).

> **Status:** implemented against OMAPI but not yet tested against a
> physical AX3/AX6 device.

## ✨ Features

- 🔍 **Discovery** — `axivity_discover()`
- 📊 **Status** — battery, self-test, memory health, live accelerometer
  reading, RTC get/set, LED colour, anti-tamper lock, ECC flag, and a raw
  `axivity_send_command()` escape hatch
- ⚙️ **Settings** — delayed activation window, session ID, metadata
  scratch buffer, accelerometer rate/range, and `axivity_reset()` (erase +
  commit, with `none`/`delete`/`quickformat`/`wipe` levels)
- 📥 **Download** — `axivity_download()`, backed by OMAPI's own background
  download thread (progress polling and cancellation included), not a
  plain file copy

There's no `axivity_open()`/`close()` step — the OMAPI session starts when
axR is loaded and stops when it's unloaded. Every function takes a
`device_id` from `axivity_discover()`.

## 🗂️ Project Structure

```
axR/
├── configure              # generates src/Makevars at install time (chmod +x!)
├── R/
│   ├── axR-package.R   # package-level documentation
│   ├── zzz.R            # .onLoad/.onUnload (OmStartup/OmShutdown), .om_check()
│   ├── discover.R        # axivity_discover()
│   ├── status.R          # battery, self-test, memory health, accelerometer,
│   │                       # RTC, LED, lock, ECC, send_command
│   ├── settings.R        # delays, session ID, metadata, accel config, reset
│   └── download.R        # data info, download, download_status/wait/cancel
├── src/
│   ├── axR-omapi.cpp     # thin Rcpp wrapper around OMAPI
│   ├── omapi/             # vendored OMAPI C library (BSD 2-clause)
│   ├── Makevars.in       # template; configure fills in the platform-specific bits
│   └── Makevars.win      # Windows build config (static, no template needed)
├── tests/testthat/
├── man/figures/logo.svg
├── DESCRIPTION
└── NEWS.md
```

## 🚀 Getting Started

### Prerequisites

- R (>= 4.1.0)
- Rcpp
- A C/C++ toolchain (Xcode CLT on macOS, Rtools44 on Windows)
- **Linux only:** `libudev-dev` (or equivalent) for device discovery

### Installation

```r
# not yet on r-universe — install from source:
remotes::install_github("circadia-bio/axR")
```

### Vignette

```r
vignette("axR")
```

Walks through discovery, status/settings, downloading, the
`axivity_copy_data()` fallback, and reading `.cwa` files with
`axivity_read_cwa()`.

## 📦 Dependencies

| Package | Version   | Purpose                          |
|---------|-----------|-----------------------------------|
| Rcpp    | >= 1.0.0  | Bridges R to the vendored OMAPI C library |

## 👥 Authors

| Role | Name | Affiliation |
|------|------|--------------|
| Author, maintainer | Lucas França | Circadia Lab, Northumbria University |

## 🤝 Related Tools

- 🧪 [**zeitR**](https://github.com/circadia-bio/zeitR) — wrist actigraphy analysis and circadian metrics
- 🧪 [**mrpheus**](https://github.com/circadia-bio/mrpheus) — raw physiological signal analysis (PSG/EEG)
- 🧪 [**syncR**](https://github.com/circadia-bio/syncR) — ecosystem integrator, pulls data into a unified participant database
- 🔬 [**circadia-bio**](https://github.com/circadia-bio) — the Circadia Lab GitHub organisation

## 📄 Licence

Released under the [MIT License](./LICENSE). Vendored OMAPI code in
`src/omapi` is BSD 2-clause, Copyright © Newcastle University — see
[`src/omapi/LICENSE.TXT`](src/omapi/LICENSE.TXT).

Copyright © Lucas França, 2026
