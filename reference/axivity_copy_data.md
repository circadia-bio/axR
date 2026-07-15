# Copy recorded data directly off a mounted Axivity volume

A fallback for when
[`axivity_discover()`](https://axr.circadia-lab.uk/reference/axivity_discover.md)/OMAPI
device access isn't working, but the device's USB mass-storage volume
mounts and is visible in Finder/`diskutil` regardless – a common split,
since the storage side and OMAPI's own IOKit-level device discovery are
independent paths (see `NEWS.md` for the discovery issues hit so far).
This bypasses OMAPI and `device_id` entirely: it's a plain file copy,
nothing more. `axR` doesn't parse `.cwa` contents – see `mrpheus` or
`zeitR` for that.

## Usage

``` r
axivity_copy_data(
  device_path,
  dest_dir,
  pattern = "\\.cwa$",
  overwrite = FALSE
)
```

## Arguments

- device_path:

  Character. Path to the mounted device volume, e.g.
  `"/Volumes/CWA17_46171"`. Find this in Finder, or with
  `list.files("/Volumes")`.

- dest_dir:

  Character. Destination directory for downloaded files. Created
  (recursively) if it doesn't already exist.

- pattern:

  Character. Regex to filter which files are copied, matched
  case-insensitively. Default `"\\.cwa$"`.

- overwrite:

  Logical. Overwrite existing files at the destination. Default `FALSE`.

## Value

Character vector of destination file paths that were successfully
copied.
