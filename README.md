# BLKGLD Lyric Video — iOS (native)

On-device iPhone companion to the desktop [lyric-video-maker](https://github.com/blkgld03/lyric-video-maker):
sync + render lyric videos entirely on-device using whisper.cpp (Metal) and AVFoundation.
No cloud services, no API keys — everything the app needs ships in the binary or is generated
on-device. See the project page in the brain vault for the full 5-phase plan.

## Status

**Phase 0 — pipeline proof.** This repo currently contains only a hello-world SwiftUI screen.
The point isn't the app — it's proving GitHub Actions can build an unsigned IPA that installs
via sideloading, before any real iOS code gets written.

## Build

Builds happen on GitHub Actions (macOS runner) — no local Xcode needed to trigger a build.
Every push to `main` (or a manual "Run workflow" click) produces an **unsigned** IPA as a
downloadable artifact under the Actions tab.

To install it: download the artifact, sign it with Sideloadly or ESign using your own Apple ID /
dev-mode pairing, then install to your iPhone. Nothing in this repo — no keys, no certs, no
personal data — is needed to sign; that all happens locally on your machine at install time.

## Local structure

- `project.yml` — [XcodeGen](https://github.com/yonaskolb/XcodeGen) spec. The actual `.xcodeproj`
  is generated at build time (in CI) and is gitignored — never hand-edit or commit it.
- `Sources/BLKGLDLyricVideo/` — Swift source.
- `.github/workflows/build-ipa.yml` — the CI pipeline.
