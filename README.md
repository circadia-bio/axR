# ⛏️ axR <img src="man/figures/logo.svg" align="right" height="140"/>

**Device discovery, status, settings, and data download for accelerometer devices.**

[![r-universe](https://circadia-bio.r-universe.dev/badges/axR)](https://circadia-bio.r-universe.dev/axR)
[![DOI](https://img.shields.io/badge/DOI-10.5281%2Fzenodo.21393892-blue)](https://doi.org/10.5281/zenodo.21393892)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![R](https://img.shields.io/badge/R-%3E%3D4.1-276DC3)](https://www.r-project.org/)
[![R CMD CHECK](https://github.com/circadia-bio/axR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/circadia-bio/axR/actions/workflows/R-CMD-check.yaml)
[![Coverage](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/circadia-bio/axR/gh-pages/badges/coverage.json)](https://github.com/circadia-bio/axR/actions/workflows/pkgdown.yaml)
[![Status](https://img.shields.io/badge/status-early%20development-orange)](https://github.com/circadia-bio/axR)
[![pkgdown](https://img.shields.io/badge/docs-axr.circadia--lab.uk-FC544A)](https://axr.circadia-lab.uk)

---

## 📖 What is axR?

`axR` talks to Axivity AX3/AX6 accelerometers over USB: discovering connected
devices, querying and setting status/configuration, and downloading recorded
`.cwa` files. It also parses those `.cwa` files directly, and -- as of a
recent addition -- Condor Instruments ActTrust `.txt` actigraphy exports,
into the same tidy epoch shape.

Rather than reimplementing the Axivity serial protocol directly, axR wraps
the Open Movement Project's
[OMAPI](https://github.com/openmovementproject/libomapi) C library
(vendored in `src/omapi`, BSD 2-clause, Newcastle University — see
[`src/omapi/LICENSE.TXT`](src/omapi/LICENSE.TXT)). OMAPI is the same library
behind Axivity's own OmGui software, and includes maintained,
platform-specific device discovery (IOKit/DiskArbitration on macOS, SetupAPI
on Windows, udev on Linux) rather than a hand-rolled equivalent.

`axR` is deliberately mostly a "dumb pipe" — it talks to the device and
moves bytes, leaving higher-level actigraphy analysis to downstream
packages such as [mrpheus](https://github.com/circadia-bio/mrpheus) or
[zeitR](https://github.com/circadia-bio/zeitR). [`axivity_read_cwa()`](#-features)
and [`read_acttrust()`](#-features) are deliberate exceptions: OMAPI already
ships a complete `.cwa` reader, and ActTrust's `.txt` export format is a
plain, well-specified text format -- so axR wraps/parses both directly
rather than building a second, differently-sourced parser for either.
`read_acttrust()` deliberately stops at device-format parsing, though: it
returns the file's own epoch columns with no pipeline-specific columns or
classes added, leaving that reshaping to downstream packages (e.g. zeitR),
the same way `axivity_read_cwa()` does.

---

> [!WARNING]
> **axR has not been fully verified against real hardware.** Live-device
> testing was performed on macOS and a real AX3. 
> `timestamp`/`x`/`y`/`z`/`device_id` from `axivity_read_cwa()` have been
> verified correct against a real recording; `temperature_c` has not, and
> is likely wrong on at least some hardware revisions. Not tested against an AX6.

---

## ✨ Features

- 🔍 **Discovery** — `axivity_discover()`
- 📊 **Status** — battery, self-test, memory health, live accelerometer
  reading, RTC get/set, LED colour, anti-tamper lock, ECC flag, and a raw
  `axivity_send_command()` escape hatch
- ⚙️ **Settings** — delayed activation window, session ID, metadata
  scratch buffer, accelerometer rate/range, and `axivity_reset()` (erase +
  commit, with `none`/`delete`/`quickformat`/`wipe` levels)
- 🧰 **`axivity_stage_device()`** — one-call deployment staging: sets
  accelerometer config, deployment window (as `start`/`stop` or
  `start`/`duration`), session ID, and metadata, then commits with
  `axivity_reset()`. For finer control, the underlying `axivity_set_*()`
  functions and `axivity_reset()` remain available individually
- 📥 **Download** — `axivity_download()`, backed by OMAPI's own background
  download thread (progress polling and cancellation included), not a
  plain file copy
- 📂 **`axivity_copy_data()`** — fallback: plain file copy from a mounted
  device volume, bypassing OMAPI/`device_id` entirely, for when
  `axivity_discover()` isn't finding the device but its mass-storage mount
  still works
- 🧮 **`axivity_read_cwa()`** — parse a `.cwa`/AX6 file directly (via OMAPI's
  own binary reader) into a tibble ready for downstream actigraphy analysis
  — no live device or prior discovery required
- 📋 **`read_acttrust()`** — parse a Condor Instruments ActTrust `.txt`
  export into the same tidy epoch shape, as a device-agnostic actigraphy
  import layer alongside `axivity_read_cwa()` -- no live device required
- 🐞 **`axivity_enable_debug_log()`** — re-enable OMAPI's internal diagnostic
  trace, for debugging device-detection issues

There's no `axivity_open()`/`close()` step — the OMAPI session starts when
axR is loaded and stops when it's unloaded. Every device-facing function
takes a `device_id` from `axivity_discover()`.

## 🗂️ Project Structure

```
axR/
├── configure              # generates src/Makevars at install time (chmod +x!)
├── cleanup                # removes configure/build artefacts (chmod +x!)
├── R/
│   ├── axR-package.R   # package-level documentation
│   ├── zzz.R            # .onLoad/.onUnload (OmStartup/OmShutdown), .om_check()
│   ├── discover.R        # axivity_discover(), axivity_enable_debug_log()
│   ├── status.R          # battery, self-test, memory health, accelerometer,
│   │                       # RTC, LED, lock, ECC, send_command
│   ├── settings.R        # delays, session ID, metadata, accel config, reset
│   ├── stage.R            # axivity_stage_device() -- one-call deployment staging
│   ├── download.R        # data info, download, download_status/wait/cancel,
│   │                       # axivity_copy_data()
│   ├── read_cwa.R        # axivity_read_cwa()
│   ├── read_acttrust.R   # read_acttrust()
│   └── utils.R           # internal message helpers (axr_abort/warn/inform), %||%
├── src/
│   ├── axR-omapi.cpp     # thin Rcpp wrapper around OMAPI
│   ├── omapi/             # vendored OMAPI C library (BSD 2-clause), with
│   │                       # axR patches -- see inline comments and NEWS.md
│   ├── Makevars.in       # template; configure fills in the platform-specific bits
│   └── Makevars.win      # Windows build config (static, no template needed)
├── vignettes/
│   ├── axR.Rmd.orig      # real vignette source (not shipped)
│   └── axR.Rmd           # pre-computed output, knitr::knit()'d from .orig
├── tests/testthat/
├── man/figures/
│   ├── logo.svg
│   └── logo.png
├── pkgdown/favicon/      # via pkgdown::build_favicons()
├── .github/workflows/    # R-CMD-check.yaml, pkgdown.yaml
├── _pkgdown.yml
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

Install from [r-universe](https://circadia-bio.r-universe.dev) (recommended — pre-built binaries):

```r
install.packages(
  "axR",
  repos = c("https://circadia-bio.r-universe.dev", "https://cloud.r-project.org")
)
```

Or install the development version from GitHub:

```r
install.packages("pak")
pak::pak("circadia-bio/axR")
```

**Linux only:** r-universe's pre-built binaries don't bundle system
libraries — `libudev-dev` (or equivalent) still needs to be installed
separately on the machine running R, regardless of install method.

### Vignette

```r
vignette("axR")
```

Walks through discovery, status/settings, deployment staging with
`axivity_stage_device()`, downloading, the `axivity_copy_data()`
fallback, and reading `.cwa` files with `axivity_read_cwa()`.

## 📦 Dependencies

| Package | Type | Purpose |
|---|---|---|
| Rcpp | Imports | Bridges R to the vendored OMAPI C library |
| cli | Imports | `read_acttrust()`'s error/warning messages |
| lubridate | Imports | `read_acttrust()`'s flexible date-time parsing |
| tibble | Suggests | `axivity_read_cwa()`/`read_acttrust()`'s return type (falls back to a plain data frame if absent) |
| testthat | Suggests | Test suite |
| covr | Suggests | Coverage reporting |
| knitr, rmarkdown, pkgdown | Suggests | Vignette and documentation site |

## 👥 Authors

| Role | Name | Affiliation |
|------|------|--------------|
| Author, maintainer | Lucas França | Circadia Lab, Northumbria University |
| Author | Mario Leocadio-Miguel | Circadia Lab, Northumbria University |
| Author | Daniel Jackson | Northumbria University |

## 📄 Citation

If you use axR in your research, please cite it:

```bibtex
@software{franca_axr_2026,
  author  = {França, Lucas and Leocadio-Miguel, Mario and Jackson, Daniel},
  title   = {{axR}: Interfacing and Retrieving Data from Accelerometer Devices},
  year    = {2026},
  version = {0.1.1},
  doi     = {10.5281/zenodo.21393892},
  url     = {https://github.com/circadia-bio/axR}
}
```

## 🤝 Related Tools

- 🧪 [**zeitR**](https://github.com/circadia-bio/zeitR) — wrist actigraphy analysis and circadian metrics
- 🧪 [**mrpheus**](https://github.com/circadia-bio/mrpheus) — raw physiological signal analysis (PSG/EEG)
- 🧪 [**syncR**](https://github.com/circadia-bio/syncR) — ecosystem integrator, pulls data into a unified participant database
- 🔬 [**circadia-bio**](https://github.com/circadia-bio) — the Circadia Lab GitHub organisation

## 📄 Licence

Released under the [MIT License](./LICENSE). Vendored OMAPI code in
`src/omapi` is BSD 2-clause, Copyright © Newcastle University — see
[`src/omapi/LICENSE.TXT`](src/omapi/LICENSE.TXT).

Copyright © Lucas França, Mario Leocadio-Miguel & Daniel Jackson, 2026
