# Installing P1 Transfer

## Requirements

- Apple Silicon Mac (M1 or newer)
- macOS 27.0 or later
- BETAFPV P1 receiver and data-capable USB cable

The application includes libmtp and libusb. You do not need Homebrew, Xcode, or additional drivers.

## Recommended: macOS installer (.pkg)

1. Open the [P1 Transfer v1.1 release](https://github.com/krisgleave/p1-transfer/releases/tag/v1.1).
2. Download `P1-Transfer-1.2-arm64.pkg`.
3. Quit any running copy of P1 Transfer.
4. Double-click the downloaded package and follow the installation instructions.
5. Open **P1 Transfer** from Applications.
6. Connect and power on your P1, then click Refresh if necessary.

The installed application is always named **P1 Transfer.app**, without a version number in its name.

## Alternative: ZIP download

Download `P1-Transfer-1.2-macOS-arm64.zip`, extract it and move **P1 Transfer.app** into Applications.

If you have an older application named `P1 Transfer v1.1.app`, remove that older copy after confirming the new version works.

## macOS security warning

P1 Transfer is ad-hoc signed but is not Apple Developer ID signed or notarised. macOS may prevent it from opening automatically.

Only proceed if you trust the downloaded application. Use **System Settings > Privacy & Security > Open Anyway** when macOS offers that option, following [Apple's guidance](https://support.apple.com/102445).

Do not disable Gatekeeper or other system-wide security protections.

## Transferring recordings

1. Quit competing MTP applications such as OpenMTP, MacDroid or Android File Transfer.
2. Connect and power on the P1 using a data-capable USB cable.
3. Open P1 Transfer and select your recordings.
4. Click **Download selected…** and choose a destination.
5. Use **Refresh** after reconnecting the receiver.

Downloads are copied into timestamped folders. Originals remain on the receiver.

The blue **Close** button at the bottom-right closes the application.

## Updating

Finish any active downloads before updating. Quit the application, then install the new package or replace the existing app.

Your downloaded recordings are not deleted by updating the application.
