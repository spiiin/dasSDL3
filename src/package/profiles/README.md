# Reference SDK fingerprints

The supported client/source revision is daScript
`ebac0ffe46ab30de6c9536f4b0af7a33ede45902` (upstream version `0.6.4`).
Older reference and official SDKs are no longer accepted.

Download the exact build from the [reference SDK release](https://github.com/spiiin/dasSDL3/releases/tag/sdk-ebac0ffe-windows-x64-r1).
`reference-sdk.json` records its URL, archive checksum and layout. Consumers
can obtain the accepted binaries without reproducing the maintainer's build.

`core.sha256` and `imgui.sha256` describe the Windows x64 MSVC 19.38 Release
`/MD` AVX2 reference build, configured with `DASSDL3_WITH_IMGUI=ON`.
The core profile does not ship ImGui; both profiles use the same runtime SDK.
The ImGui fingerprint additionally covers native headers/sources and its
import library/module and Clipboard module.

Fingerprints use the relative-path/SHA256 format emitted by
`tools/stage_daspkg.py --source --sdk <SDK>`. They must match in full and are
never regenerated during installation. Binary hashes deliberately reject
other builds, even potentially compatible rebuilds of the same source commit.
This is not a claim of general daScript ABI stability.

To update a profile, stage a candidate, validate actual package installation,
interpreter execution, relocation and standalone release, then review its
`sdk.sha256`. Build binary packages separately for the accepted SDK.

These committed reference hashes are Windows-only. Native Mac repository
packages use a staged fingerprint supplied through
`DASSDL3_PACKAGE_SDK_FINGERPRINT`, against the same pinned source revision.
The Windows SDK archive cannot be used for native Mac package linkage.
