# Download recorded data off an Axivity device

Wraps OMAPI's `OmBeginDownloading()`, which runs the download on a
background thread inside the library. `axR` doesn't parse `.cwa`
contents – see `mrpheus` or `zeitR` for that.

## Usage

``` r
axivity_download(
  device_id,
  dest_file,
  offset_blocks = 0L,
  length_blocks = -1L,
  blocking = TRUE
)
```

## Arguments

- device_id:

  Integer device ID, as returned by
  [`axivity_discover()`](https://axr.circadia-lab.uk/reference/axivity_discover.md).

- dest_file:

  Character. Destination file path (existing files at this path are
  truncated).

- offset_blocks:

  Integer. Start offset of the download, in blocks. Default `0`.

- length_blocks:

  Integer. Length to download, in blocks. Default `-1` (all).

- blocking:

  Logical. If `TRUE` (default), block until the download completes,
  fails, or is cancelled – equivalent to calling
  [`axivity_download_wait()`](https://axr.circadia-lab.uk/reference/axivity_download_status.md)
  immediately after. If `FALSE`, return as soon as the download starts;
  poll with
  [`axivity_download_status()`](https://axr.circadia-lab.uk/reference/axivity_download_status.md).

## Value

If `blocking = TRUE`, a list with `status` (one of `"complete"`,
`"error"`, `"cancelled"`) and `value` (a diagnostic code if `status` is
`"error"`). If `blocking = FALSE`, invisibly `NULL`.
