# axR: Interfacing and Retrieving Data from Accelerometer Devices

Talks to Axivity AX3/AX6 accelerometer devices: discovery, status
(battery, self-test, memory health, accelerometer, RTC, LED, lock, ECC),
settings (delays, session ID, metadata, accelerometer config, erase),
data download, and reading recorded `.cwa`/AX6 binary files
([`axivity_read_cwa()`](https://axr.circadia-lab.uk/reference/axivity_read_cwa.md)).
Also reads Condor Instruments ActTrust `.txt` actigraphy exports
([`read_acttrust()`](https://axr.circadia-lab.uk/reference/read_acttrust.md))
into the same tidy epoch shape, as a device-agnostic actigraphy import
layer.

## Details

axR was originally scoped as a "dumb pipe" – talk to the device, move
bytes, leave file parsing to downstream packages.
[`axivity_read_cwa()`](https://axr.circadia-lab.uk/reference/axivity_read_cwa.md)
and
[`read_acttrust()`](https://axr.circadia-lab.uk/reference/read_acttrust.md)
are deliberate exceptions: OMAPI already ships a complete binary file
reader (`omapi-reader.c`), and ActTrust's `.txt` export is a plain,
well-specified text format – wrapping/parsing both directly is simpler
and more consistent than reimplementing either format a second time in
zeitR from a different reference pipeline. axR does not do any
higher-level actigraphy analysis on the parsed data (sleep detection,
non-wear detection, etc.) – that's still zeitR's job, downstream of the
tibbles these functions return.

## Implementation

Rather than reimplementing the Axivity serial protocol or `.cwa` binary
format directly, axR wraps the Open Movement Project's OMAPI C library
(vendored in `src/omapi`, BSD 2-clause, Newcastle University – see
`src/omapi/LICENSE.TXT`). OMAPI is the same library behind Axivity's own
OmGui software, and includes maintained, platform-specific device
discovery (IOKit/DiskArbitration on macOS, SetupAPI on Windows, udev on
Linux) rather than a hand-rolled equivalent.

The OMAPI session is started when axR is loaded (`OmStartup()` in
`.onLoad()`) and shut down when it's unloaded (`OmShutdown()` in
`.onUnload()`) – there's no separate
`axivity_open()`/[`close()`](https://rdrr.io/r/base/connections.html)
step. Every device-facing function takes a `device_id`, obtained from
[`axivity_discover()`](https://axr.circadia-lab.uk/reference/axivity_discover.md).
[`axivity_read_cwa()`](https://axr.circadia-lab.uk/reference/axivity_read_cwa.md),
[`read_acttrust()`](https://axr.circadia-lab.uk/reference/read_acttrust.md),
and
[`axivity_copy_data()`](https://axr.circadia-lab.uk/reference/axivity_copy_data.md)
are the exceptions – they work on a file already on disk and don't need
a live device connection at all.

## See also

Useful links:

- <https://axr.circadia-lab.uk>

- <https://github.com/circadia-bio/axR>

- Report bugs at <https://github.com/circadia-bio/axR/issues>

## Author

**Maintainer**: Lucas França <lucas.franca@northumbria.ac.uk>
([ORCID](https://orcid.org/0000-0003-0853-1319))

Authors:

- Lucas França <lucas.franca@northumbria.ac.uk>
  ([ORCID](https://orcid.org/0000-0003-0853-1319))

- Mario Leocadio-Miguel <mario.miguel@northumbria.ac.uk>
  ([ORCID](https://orcid.org/0000-0002-7248-3529))

- Daniel Jackson ([ORCID](https://orcid.org/0000-0002-6349-5026))
