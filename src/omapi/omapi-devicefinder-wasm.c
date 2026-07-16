// axR patch: no-op device-finder stub for WebAssembly/Emscripten builds
// (e.g. r-universe's webR/wasm target).
//
// There is no udev/IOKit/SetupAPI equivalent inside a WASM sandbox -- and
// even if there were, raw USB/serial device access isn't something a WASM
// module running in a browser can do at all. Rather than fail the build
// (as it did trying to link against a nonexistent -ludev), this provides
// genuine no-op implementations of the two functions OMAPI's platform-
// independent code (omapi-main.c) calls: OmStartup()/OmShutdown() call
// these, but nothing ever calls OmDeviceDiscovery() to register a device,
// so OmGetDeviceIds() always returns 0 and axivity_discover() returns an
// empty data frame -- gracefully, not a build failure. Every other axR
// function that doesn't need a live device (axivity_read_cwa(),
// axivity_copy_data()) still works normally under this target.

#include "omapi-internal.h"

void OmDeviceDiscoveryStart(void)
{
    // Intentionally empty -- see file header comment.
}

void OmDeviceDiscoveryStop(void)
{
    // Intentionally empty -- see file header comment.
}
