# Windows build (GitHub Actions)

`.github/workflows/build.yml` builds 32- and 64-bit Windows installers of
this PulseView on every push to `master`, on tags, and from the Actions tab
("Run workflow"). Each run's installers are under **Artifacts** on its
summary page; on a tag they are also attached to the GitHub release.

It uses sigrok's MXE Docker image (`ghcr.io/sigrokproject/sigrok-mxe`) and
the dependency scripts from sigrokproject/sigrok-build, with these changes:

- **libusb 1.0.30.** The image's MXE has sigrok's old libusb fork
  (1.0.20-rc3 "event-abstraction"). The workflow copies `libusb1.mk` and
  `libusb1-1-fixes.patch` from this folder into MXE's `src/` and rebuilds
  only libusb1. The patch keeps sigrok's RAW_IO policy for WinUSB
  (`LIBUSB_SIGROK_RAWIO=0` turns it off at run time).
- **libsigrok from github.com/dovandung/libsigrok** (master): stock-libusb
  USB event source, Sipeed SLogic, Cypress FX3, hsdaoh-la, faster soft
  trigger. Change `LIBSIGROK_REPO` / `LIBSIGROK_BRANCH` in the workflow to
  build another one.
- **libhsdaoh** is built first (`HSDAOH_LIBUSB=mxe`), so hsdaoh-la is
  included. If it fails, the build goes on without that driver.
- sigrok repositories are cloned from their GitHub mirrors.

The same two files work for a local MXE (`~/mxe-git`): copy them into
`src/` and run `make MXE_TARGETS=i686-w64-mingw32.static.posix libusb1`.
