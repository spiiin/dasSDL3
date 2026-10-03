# Publication handoff: dasSDL3 0.1.0

Prepared artifacts:
- VERSION is 0.1.0, also used by root CMake and the installed SDK version.
- Root .das_package declares spiiin, MIT, minimum SDK 0.6.4, source and tags.
- 0.1.0.md is the draft GitHub release body.
- Source installation validates SDK fingerprints; minimum SDK alone is not ABI validation.
- LICENSE, VERSION and licenses/ are included in staged packages and releases.

No release tag, GitHub release or daspkg-index PR has been created.
Review the exact branch contents before publication.

## Local metadata check

~~~powershell
python tests/test_daspkg_manifest.py --das-root C:/path/to/daslang_bundle
~~~

This executes upstream metadata, resolution, dependency, build-declaration and
release-declaration readers for core and imgui. It does not invoke cmake, download,
introduce, create tags or contact the index. It is also registered as
sdl3_daspkg_manifest after package CMake reconfiguration.

## Publication sequence — only after authorization

1. Review and commit the intended tree, preserving unrelated concurrent work.
2. Run affected package tests against that commit. Repository tests currently
   overlay pending entry files onto HEAD; they are not a public-tag test.
3. Create and push v0.1.0 at the reviewed commit, plus the branch updates.
4. Install github.com/spiiin/dasSDL3@0.1.0 into fresh core/GUI consumers using
   the pinned reference SDK. The actual remote tag cannot be tested before it exists.
5. Publish the GitHub release using 0.1.0.md, updating its draft status.
   Verification ZIPs are example applications, not generic SDK DLLs.
   Binaries from different SDK builds are not interchangeable.
6. Register through daspkg introduce with DASSDL3_PACKAGE_PROFILE=core.
   Index metadata records the default profile; imgui adds its dependency at
   install time. introduce creates/pushes an index branch and opens a PR:
   do not run it as a metadata check. Attach the created PR to this chat.
7. Once the index PR is merged, test installation by package name.

No-version/latest intentionally follows main. Use @0.1.0 for the release tag.
This initial version does not promise a stable 1.x API.

## Verification scope

Use the current validation record in ../daspkg.md. An earlier SDK kit passed
on a second Windows machine; that does not validate the updated SDK on that
machine. Hardware/Web/other OS coverage remains separate.
