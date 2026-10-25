# Windows build (GitHub Actions)

`.github/workflows/build.yml` builds 32- and 64-bit Windows installers of
this PulseView on every push to `master`, on tags, and from the Actions tab
("Run workflow"). Each run's installers are under **Artifacts** on its
summary page; on a tag they are also attached to the GitHub release.

## First: build the MXE images (once)

sigrok's MXE Docker image (`ghcr.io/sigrokproject/sigrok-mxe`) can no
longer be pulled ("denied"), so this repository builds its own:
**Actions > Build MXE image > Run workflow** (`mxe-image.yml`). It builds
`sigrok-mxe.Dockerfile` (sigrok-build's Dockerfile, one target per image,
Debian bookworm, libusb 1.0.30) and pushes
`ghcr.io/<owner>/sigrok-mxe-i686` and `-x86_64`. Each takes a few hours;
if a job times out, run it again and it continues from its layer cache.
It runs again by itself when the Dockerfile or the libusb files change.

## Then: the PulseView build

`build.yml` runs in those images with the dependency scripts from
sigrokproject/sigrok-build, with these changes:

- **libusb 1.0.30** with sigrok's RAW_IO policy (`libusb1.mk`,
  `libusb1-1-fixes.patch`; `LIBUSB_SIGROK_RAWIO=0` turns the policy off at
  run time). The images already have it; if these files are newer than the
  image, the build rebuilds only libusb1.
- **libsigrok from github.com/dovandung/libsigrok** (master): stock-libusb
  USB event source, Sipeed SLogic, Cypress FX3, hsdaoh-la, faster soft
  trigger. Change `LIBSIGROK_REPO` / `LIBSIGROK_BRANCH` in the workflow to
  build another one.
- **libhsdaoh** is built first (`HSDAOH_LIBUSB=mxe`), so hsdaoh-la is
  included. If it fails, the build goes on without that driver.
- sigrok repositories are cloned from their GitHub mirrors.

The same two files work for a local MXE (`~/mxe-git`): copy them into
`src/` and run `make MXE_TARGETS=i686-w64-mingw32.static.posix libusb1`.
