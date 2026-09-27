# Validated SDK fingerprints

These files pin the SDK tested by the Windows x64 Release /MD AVX2 package
profiles. core.sha256 and imgui.sha256 refer to the local reference build of
daScript 35bf260c0d8a79b94c64005bd3d2435adcf7e261.
core-official-0.6.4.sha256 pins the official Windows x86_64 v0.6.4 archive;
URL, archive checksum and scope are in official-0.6.4.json.
They use the same relative-path/SHA256 format as stage_daspkg.py source packages.
Do not regenerate them during install: that would accept any consumer SDK.

To propose another SDK, stage a source core/GUI package against it using
tools/stage_daspkg.py, validate installation/interpreter/standalone behavior,
then review the resulting sdk.sha256 as a candidate profile update.
Binary hashes intentionally reject even potentially compatible SDK rebuilds.
No claim of general daScript ABI stability is made.

Repository core and ImGui installation accept either complete matching snapshot.
imgui-official-0.6.4.sha256 additionally pins the official ImGui import library,
ImGui module and Clipboard module. Missing native ImGui sources are obtained by
CMake from the exact archive/hash pinned in the SDK release build.
Binary modules must be built separately for each SDK; this allowlist applies
to source builds, not DLL interchange.
