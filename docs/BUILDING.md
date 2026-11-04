# Building P1 Transfer

End users should download a packaged release. These instructions are for contributors.

## Prerequisites

- Apple Silicon Mac with macOS 27.0 or newer.
- Apple Command Line Tools with a macOS 27 SDK (`xcode-select --install` if absent).
- Python 3.
- For a fresh dependency setup: Homebrew with libmtp 1.1.23 and libusb 1.0.30.

Full Xcode is optional. No Apple Developer membership is required for a locally signed build.

## Build

```sh
brew install libmtp
python3 scripts/build.py
```

The script checks dependency versions and source-archive hashes, compiles the GUI, copies only the required helpers and libraries, relocates their library paths, generates the multi-resolution app icon, includes licences and source archives, signs locally, and verifies the bundle signature.

Output: `build/P1-Transfer-1.8-macOS-arm64.zip` and a SHA-256 checksum file. The result is standalone and does not depend on Homebrew at runtime.

If Homebrew has upgraded the libraries beyond the pinned versions, update dependency source archives, hashes and notices together rather than bundling new binaries with mismatched source. You can also reuse bundled dependencies from a trusted existing release:

```sh
python3 scripts/build.py --dependencies-from-app "/path/to/P1 Transfer.app"
```

This is the build path verified for the first public source package after the development Homebrew packages were removed.

## Checks

```sh
python3 scripts/test.py
```

The checks exercise selection, selection locking during a transfer, stopping connection polling, and visibility of completed files. They do not replace a real-device transfer test. Hardware validation should include a video, several sidecars, reconnect/refresh, output file sizes and Finder visibility.

## Rebuilding the LGPL dependencies

Unmodified corresponding upstream sources and their SHA-256 values are included under `third_party/`. Extract libusb and follow its `INSTALL` instructions, then build libmtp against that installation using its `INSTALL` instructions. These are upstream autotools projects; dependency builds may require additional build tools such as pkg-config.

Replace `libmtp.9.dylib`, `libusb-1.0.0.dylib`, `mtp-files` and `mtp-connect` in a trusted dependency bundle, naming the last helper `mtp-getfile`. Run the packaging script with `--dependencies-from-app` to relocate and sign the resulting app. The libmtp `mtp-connect` program dispatches based on its executable name.

Library replacement and debugging modified libraries are allowed under their licences. Re-sign your modified local bundle. No Apple signing identity is needed for an ad-hoc signature.

## Supporting older Macs

Current release binaries target macOS 27 and arm64 throughout. Supporting earlier macOS requires rebuilding the GUI **and all helpers/libraries** for an older deployment target and testing them there. Intel support requires x86_64 builds for every component (or universal builds), not just a change to Info.plist.

## Public signing and notarisation

The script currently uses local/ad-hoc signing. For smoother public installation, the maintainer can use an Apple Developer ID Application certificate, hardened runtime settings appropriate to the bundle, and Apple's notarisation service, then staple and verify the ticket. See https://developer.apple.com/developer-id/ and https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution.

Keep certificates, private keys, account credentials and notarisation secrets out of the repository. A certificate, private key or Apple account is not included with this project.
