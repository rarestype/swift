# swift

Builds the Swift compiler, standard library and SwiftPM for Linux, from Apple’s release tags plus a short list of upstream fixes, as archives that replace those parts of Apple’s toolchain. Also publishes signed [swift-syntax](https://github.com/swiftlang/swift-syntax) prebuilts for macros, which our SwiftPM uses.

Each archive is extracted over the `usr` of Apple’s toolchain for the same release. It replaces only files that Apple’s toolchain already has, of the same kind: the compiler (`swift-frontend`, which links LLVM) with its own libraries, and the runtime and standard library, dynamic and static, with their modules. It also replaces SwiftPM, described below. Everything else stays Apple’s: the driver, Foundation, LLDB, and what runs while compiling outside the compiler, which is the swift-syntax libraries, the macro plugins, and `swift-plugin-server`. The compiler identifies itself exactly as Apple’s does, since it has to load the modules that Apple’s compiler built. `usr/share/swift/rarest-overlay.txt` records which fixes a toolchain carries.


## SwiftPM and prebuilts

SwiftPM comes from [rarestype/swift-package-manager](https://github.com/rarestype/swift-package-manager), which carries [swiftlang/swift-package-manager#10404](https://github.com/swiftlang/swift-package-manager/pull/10404), so that building a single product (`swift build --product`, `swift package js`) uses prebuilt swift-syntax instead of compiling it. It fetches prebuilts from `https://get.rarestype.com/swift/prebuilts`, and trusts [`Certificates/root.cer`](Certificates/root.cer) by default. It is built with the compiler from the same archive, and against the dependency revisions tagged for the release.

The archive replaces Apple’s `swift-package`, which every other SwiftPM command links to, and the Swift Build resource bundles in `share/pm`. It adds the license files of every package linked into SwiftPM, under `share/swift-package-manager/licenses`, at their original paths.

The prebuilts are built with the same compiler, and signed by the `Deploy` workflow with the `PREBUILTS_SIGNING_KEY` secret, whose certificate chain is in `Certificates/`. A prebuilt that is already published is never replaced.


## Releases

`Releases/<release>` pins one Swift release, such as `6.4.2-RELEASE`. It lists the upstream commits to cherry-pick, as `<swiftlang repository> <commit>`, the SwiftPM fork commit to build, and the swift-syntax versions to build prebuilts for. A commit qualifies if it is already in one of Apple’s branches, or is our own fix with an open pull request upstream. When an Apple release contains a commit, the build fails until the commit is removed from the list, so the list never carries a patch that does nothing. Every patch has a reproducer in `Tests/Reproducers`.

A release gets an archive even when its list is empty, so that the path the images depend on keeps working.

The `Watch` workflow opens an issue every Monday for each Swift release that has no pin file yet.


## Building a release

1. Rebase the SwiftPM fork’s commits onto the new release tag, as a new branch such as `rarest/6.4.2`. Never force-push a branch that a release pins.
2. Add `Releases/<release>`, carrying over each patch the release doesn’t contain, and pinning the new SwiftPM branch’s head, in a pull request. The pull request builds and tests it.
3. Once it merges, run `Deploy` with the release. It publishes the prebuilts, then `swift-<release>-<commit>`, which is never replaced, with an archive and a checksum for each architecture.
4. Bump the image to the new archive and checksums.

Each architecture builds on a standard GitHub runner, in about three hours, and SwiftPM and the prebuilts after it. The build uses the compiler and standard library settings of Apple’s `buildbot_linux,no_assertions` preset, and installs the components that Apple’s toolchain ships.


## The gate

Before a release is published, for each architecture:

- `Scripts/Compare` checks that the archive can replace Apple’s files. The standard library and runtime, which both builds compile with the compiler they just built, must export exactly the same symbols as Apple’s, and every module interface must have been compiled with the same flags. What the host compiler builds, such as `swift-frontend`, can’t match exactly, because Apple builds its compiler with an older host compiler and linker. So with the archive installed over a copy of Apple’s toolchain, every executable and library in it must still find every library and symbol it needs, and every runpath must stay inside the toolchain.
- `Scripts/Test` installs the archive over Apple’s toolchain, as the images do. It runs each reproducer, optimized, and builds a package that uses a macro, to check that the compiler still runs macro plugins.
- `Scripts/VerifyPrebuilts` checks that our SwiftPM downloads and unpacks the signed prebuilts for its architecture, from a local copy. In pull requests, the prebuilts are signed with a throwaway certificate chain from `Scripts/MakeTestCertificates`, which SwiftPM is told to trust. `Deploy` signs them with the real key, and checks them against the root certificate built into SwiftPM.
