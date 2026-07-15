# Enable OMAPI's internal debug log

A diagnostic escape hatch for when
[`axivity_discover()`](https://axr.circadia-lab.uk/reference/axivity_discover.md)
isn't finding a device you expect it to. OMAPI logs internally via its
own `OmLog()`, but axR's default log target is `NULL` (so compiled code
doesn't write to stderr unprompted – see `NEWS.md`). This re-enables it.

## Usage

``` r
axivity_enable_debug_log(file = NULL)
```

## Arguments

- file:

  Character path to a log file, or `NULL` (default) to log to stderr. A
  file is more reliable for diagnostic purposes: OMAPI's discovery
  thread logs from a background pthread, and raw stderr writes from a
  non-R thread don't always reach the R console/terminal depending on
  the frontend – a file sidesteps that ambiguity.

## Value

Invisibly, the OMAPI status code (negative indicates failure, e.g. the
file couldn't be opened).

## Details

**Important:** this only controls where log lines go. Whether anything
is logged *at all* is controlled by OMAPI's debug level, which is read
from the `OMDEBUG` environment variable once, at `OmStartup()` time –
i.e. before [`library(axR)`](https://axr.circadia-lab.uk) runs. If
you're not seeing log output after calling this, set `OMDEBUG` (e.g.
`Sys.setenv(OMDEBUG = "3")`) *before* loading axR, in a fresh R session,
then call this function and retry.
