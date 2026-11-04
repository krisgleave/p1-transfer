# Third-party notices

The Swift GUI and original project assets are MIT licensed, copyright 2026 Kris Gleave (KrisTalksTech). These terms do not replace the licences of third-party components.

| Component | Version in release 1.8 | Licence | Project |
|---|---|---|---|
| libmtp and its mtp-files / mtp-connect tools | 1.1.23 | LGPL-2.1-or-later | https://github.com/libmtp/libmtp |
| libusb | 1.0.30 | LGPL-2.1-or-later | https://github.com/libusb/libusb |

Full licence texts and author lists are in `third_party/licences/`. Corresponding upstream source archives are in `third_party/sources/`, and are also included in app releases under `Contents/Resources/Source/`.

The distributed binaries came from Homebrew's Apple Silicon macOS 27 bottles. Their source code was not modified. Their Mach-O library paths were relocated to app-local paths and they were locally re-signed. `mtp-getfile` is a copy of libmtp's `mtp-connect` executable, which selects its behaviour from the executable name. System-provided Apple libraries are not redistributed.

Source archive SHA-256 values:

```
74a2b6e8cb4a0304e95b995496ea3ac644c29371649b892b856e22f12a0bdeed  libmtp-1.1.23.tar.gz
fea36f34f9156400209595e300840767ab1a385ede1dc7ee893015aea9c6dbaf  libusb-1.0.30.tar.bz2
```

Users may modify and replace the LGPL libraries and debug those modifications, subject to the applicable licences. No project restriction prohibits that. Rebuilding or replacing components requires re-signing the local app. See `docs/BUILDING.md` and the upstream INSTALL instructions for dependency builds.

The app icon was created with an AI image-generation tool. It uses no official BETAFPV or Apple logo. Compatibility names and third-party marks remain the property of their respective owners.
