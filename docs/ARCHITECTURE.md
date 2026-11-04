# Architecture and limits

`Sources/P1Transfer.swift` contains a native AppKit application. It launches its bundled helpers through Foundation `Process` with argument arrays, not a shell.

1. `mtp-files` opens the MTP session and returns names, object IDs and reported sizes.
2. Checkbox state is keyed by object ID.
3. The download action snapshots the checked files and copies them sequentially with `mtp-getfile`.
4. Data is written to a unique temporary file in the destination directory. The UI samples its size every 0.2 seconds to calculate aggregate progress and average speed.
5. Exit status and final byte count must match before the temporary file is renamed. macOS hidden flags are cleared after completion.

The original recordings are never deleted by the app. It has no source-delete, upload or format actions. A failed temporary download is removed, but previously completed copies remain.

Before connection, a four-second timer uses `ioreg` to look for the tested receiver's USB name, Sirius, and attempts to list files when it appears. A successful listing stops that timer. Refresh can be requested manually. Connection monitoring is therefore tailored to the tested device and is not a general USB discovery service.

## Known limits

- Current binaries require Apple Silicon and macOS 27.0+.
- Only one connected MTP receiver is supported. Helpers choose their default device; disconnect other MTP devices.
- Names, sizes and IDs come from the receiver; refresh after recordings or storage change.
- Files with slash characters or leading dots are excluded from the displayed list.
- Transfers are sequential and use one helper process per file.
- Listing times out after 30 seconds; each file transfer times out after 600 seconds.
- There is no cancel, resume, retry queue or checksum comparison.
- There is no confirmation prompt on quit during a transfer; finish a transfer before quitting. A force-quit can leave a `.partial` file in the destination.
- Capacity is read through MTP, not through a standard mounted disk.
- Progress uses filesystem size observations; buffering can make it update in steps.
- Average speed includes session setup time. The ETA can fluctuate, especially early in a batch.
- Timestamped destination folders use second precision. Starting two batches in the same second in the same destination can encounter existing filenames; the app does not intentionally overwrite them.
- This is file transfer only, not a live video receiver app or firmware utility.

No application analytics or network calls are implemented in the app. GitHub, Homebrew and source downloads are outside normal app operation and only used for distribution/development.
