# P1 Transfer 1.1

- Consistent outer margins around the progress, file list and action buttons.
- Blue download button when files are selected; disabled when nothing can be downloaded.
- Title bar: P1 Transfer v1.1 — by KrisTalksTech.

The standalone dependencies, copy-only behaviour and file naming are unchanged. Apple Silicon, macOS 27.0 or later. Locally signed, not Apple-notarized.

# P1 Transfer 1.0 — first community release

A free, standalone Mac utility for downloading BETAFPV P1 recordings and SRT sidecar files.

Created by **Kris Gleave (KrisTalksTech)**, with implementation assistance from OpenAI Codex.

## Included

- Native checkbox list with Select All and Clear.
- Batch download percentage, average speed and estimated time remaining.
- Timestamped destination folders using `P1-recordings-yyyyMMdd-HHmmss`.
- Copies only; original recordings stay on the P1.
- Bundled libmtp and libusb, with their licences and corresponding source archives.

## Requirements and status

**Apple Silicon, macOS 27.0 or newer.** No Homebrew, Xcode, separate drivers or Terminal commands required for end users. Ad-hoc signed, not Apple Developer ID signed or notarised; macOS may require explicit per-app approval.

Tested during development on an M4 Pro MacBook Pro and a P1 reporting BETAFPV P1 Rev A. Community feedback on other P1 variants is welcome. This is an independent utility, not an official BETAFPV product.

Close other MTP apps before connecting. The current transfer timeout is 10 minutes per file. See README for limits and troubleshooting.
