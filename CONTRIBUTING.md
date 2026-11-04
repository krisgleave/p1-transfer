# Contributing

Thanks for helping make P1 file transfers simpler for the FPV community.

## Report a problem

Check existing issues first. Include your Mac chip, exact macOS version, P1 model and firmware if known, app version, which other MTP apps were running, and what happened. For transfer failures, include file size and whether a smaller file works. Redact serial numbers, personal paths and private recordings from screenshots and logs.

Do not post passwords, account tokens or private video files. Security concerns should be discussed without sensitive details until a private channel is agreed.

## Code contributions

1. Fork the repository and create a branch.
2. Follow `docs/BUILDING.md` to build the app.
3. Run `python3 scripts/test.py`.
4. For transfer changes, test with a real receiver. Verify several selected files, a large video, disconnect handling and Finder visibility. No physical-device test should delete source recordings.
5. Open a pull request explaining the change and the checks performed.

Keep downloads non-destructive. Do not introduce uploads, deletes, formatting, analytics or network requests into normal app operation without a clear design discussion. Keep credentials out of the repository. Donations should remain optional.

Contributions to project-owned code are submitted under the MIT licence. Preserve upstream notices and licences when changing bundled dependencies.
